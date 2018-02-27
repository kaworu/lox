// Lox Scanner, lex a string into a stream of tokens.
class Scanner: IteratorProtocol {
  // Run the scanner on the given lox source and return an array of tokens.
  static func scan(source: String) -> [Token] {
    var tokens: [Token] = []
    let scanner = Scanner(source: source)
    while let token = scanner.next() {
      tokens.append(token)
    }
    return tokens
  }

  var peeker: Peeker

  // Create a new scanner from a source input sting.
  init(source: String) {
    self.peeker = Peeker(source)
  }

  // Return the next token scanned or nil if the end of input is reached.
  func next() -> Token? {
    // Returns true if the given character is blank, false otherwise.
    func is_blank(_ c: Character) -> Bool {
      return c == " " || c == "\t" || c == "\r" || c == "\n"
    }

    // Returns true if the given character is not nil a digit, false otherwise.
    // NOTE: we have the optional dance because of how number() is implemented,
    // see below.
    func is_digit(_ opt: Character?) -> Bool {
      guard let c = opt else { return false }
      return c >= "0" && c <= "9"
    }

    // Returns true if the given character is alphabetical, false otherwise.
    // Note that underscore `_' is accepted.
    func is_alpha(_ c: Character) -> Bool {
      return c >= "a" && c <= "z" || c >= "A" && c <= "Z" || c == "_"
    }

    // Returns true if the given character is alphabetical or a digit, false
    // otherwise. Note that underscore `_' is accepted.
    func is_alnum(_ c: Character) -> Bool {
      return is_alpha(c) || is_digit(c)
    }

    // advance the peeker until we find something of interest.
    peeker.skip(while: is_blank)
    // Check if we reached the end of input.
    guard let c = peeker.next() else { return nil }

    // Helper to create a scanned token.
    func tokenize(_ kind: Token.Kind) -> Token {
      let len = peeker.offset - c.offset;
      return Token(kind: kind, location: (c.offset, len), scanner: self)
    }

    // Scan a literal string. Can produce an .unterminated_string token if the
    // end of input is reached before finding a closing double quote.
    func string() -> Token {
      // XXX: no way to escape double quote in a string (i.e. `"')
      let content = peeker.skip(while: { $0 != "\"" })
      // Here we are on the closing double quote or at EOF.
      if peeker.advance() {
        return tokenize(.string(String(content)))
      } else {
        return tokenize(.unterminated_string)
      }
    }

    // Scan a literal number, always succeed.
    func number() -> Token {
      var digits = [c.element] + peeker.skip(while: is_digit)
      let maybe_dot   = peeker.peek()?.element
      let maybe_digit = peeker.peek2()?.element
      if maybe_dot == "." && is_digit(maybe_digit) {
        digits.append(peeker.next()!.element) // the dot
        digits.append(contentsOf: peeker.skip(while: is_digit))
      }
      let n = Double(String(digits))!
      return tokenize(.number(n))
    }

    // Scan an identifier or a keyword, always succeed.
    func identifier() -> Token {
      let chars = [c.element] + peeker.skip(while: is_alnum)
      let word  = String(chars)
      let kind  = Token.Kind.keywords[word] ?? .identifier(word)
      return tokenize(kind)
    }

    // Skip the input until we find a blank character and create an
    // .unknown_stuff token containing the skipped characters.
    func unkown() -> Token {
      let chars = peeker.skip(while: { !is_blank($0) })
      return tokenize(.unknown_stuff(String(chars)))
    }

    // Skip the input until we find a newline and returns the next token
    // (if any).
    func comment() -> Token? {
      // A line comment goes until the end of the line.
      peeker.skip(while: { $0 != "\n" })
      return self.next()
    }

    switch c.element {
      case "(": return tokenize(.open_paren)
      case ")": return tokenize(.close_paren)
      case "{": return tokenize(.open_brace)
      case "}": return tokenize(.close_brace)
      case ",": return tokenize(.comma)
      case ".": return tokenize(.dot)
      case "-": return tokenize(.minus)
      case "+": return tokenize(.plus)
      case ";": return tokenize(.semi_colon)
      case "*": return tokenize(.star)
      case "!": return peeker.match("=") ? tokenize(.bang_eq) : tokenize(.bang)
      case "=": return peeker.match("=") ? tokenize(.eq_eq)   : tokenize(.eq)
      case ">": return peeker.match("=") ? tokenize(.gt_eq)   : tokenize(.gt)
      case "<": return peeker.match("=") ? tokenize(.lt_eq)   : tokenize(.lt)
      case "/": return peeker.match("/") ? comment()       : tokenize(.slash)
      case "\"":
        return string()
      case _ where is_digit(c.element):
        return number()
      case _ where is_alpha(c.element):
        return identifier()
      default:
        return unkown()
    }
  }

  // Peekable iterator over enumerated string characters.
  class Peeker: IteratorProtocol {
    typealias Element = (offset: Int, element: Character)

    let source: String
    var chars: EnumeratedIterator<String.Iterator>
    var lookahead: (Element?, Element?)

    // Create an iterator from a given String.
    init(_ source: String) {
      self.source = source
      self.chars = source.enumerated().makeIterator()
      self.lookahead = (self.chars.next(), self.chars.next())
    }

    // Returns the next character without consuming it.
    func peek() -> Element? {
      return lookahead.0
    }

    // Returns the character after next one without consuming it.
    func peek2() -> Element? {
      return lookahead.1
    }

    // Returns the next character and advance the iterator.
    func next() -> Element? {
      let ret = lookahead.0
      lookahead = (lookahead.1, chars.next())
      return ret
    }

    // Advance the iterator and return true if an element was consumed, false
    // otherwise.
    @discardableResult
    func advance() -> Bool {
      return next() != nil
    }

    // Returns true and consume the next character if it is the expected one,
    // returns false otherwise.
    func match(_ expected: Character) -> Bool {
      if peek()?.element == expected {
        advance()
        return true
      } else {
        return false
      }
    }

    // Skip characters while the given predicate closure return true. Returns
    // all the skipped characters.
    @discardableResult
    func skip(while predicate: (Character) -> Bool) -> [Character] {
      var chars: [Character] = []
      while let c = peek() {
        guard predicate(c.element) else { break }
        chars.append(c.element)
        advance()
      }
      return chars
    }

    // The offset of the peekable character, or source.count when we're at the
    // end of the string.
    var offset: Int {
      return peek()?.offset ?? source.count
    }
  }

  // What the scanner attempt to produce from a source string.
  struct Token {
    // Type of tokens.
    enum Kind {
      // Single-character tokens.
      case open_paren  // `('
      case close_paren // `)'
      case open_brace  // `{'
      case close_brace // `}'
      case comma       // `,'
      case dot         // `.'
      case minus       // `-'
      case plus        // `+'
      case semi_colon  // `;'
      case slash       // `/'
      case star        // `*'
      // One or two character tokens.
      case bang        // `!'
      case bang_eq     // `!='
      case eq          // `='
      case eq_eq       // `=='
      case gt          // `>'
      case gt_eq       // `>='
      case lt          // `<'
      case lt_eq       // `<='
      // Literals.
      case identifier(String)
      case string(String)
      case number(Double)
      // Keywords.
      case `and`
      case `class`
      case `else`
      case `false`
      case `fun`
      case `for`
      case `if`
      case `nil`
      case `or`
      case `print`
      case `return`
      case `super`
      case `this`
      case `true`
      case `var`
      case `while`
      // Errors
      case unterminated_string
      case unknown_stuff(String)

      // Dictionary of literal string to keywords token types.
      static let keywords: [String: Token.Kind] = [
        "and":    .and,
        "class":  .class,
        "else":   .else,
        "false":  .false,
        "fun":    .fun,
        "for":    .for,
        "if":     .if,
        "nil":    .nil,
        "or":     .or,
        "print":  .print,
        "return": .return,
        "super":  .super,
        "this":   .this,
        "true":   .true,
        "var":    .var,
        "while":  .while,
      ]
    }

    let kind: Kind
    let location: (offset: Int, len: Int)
    let scanner: Scanner

    // The substring in the source that is matched by this token.
    var lexeme: String {
      // NOTE: probably super-slow, but that's ok since it should be used only
      // by tests and error handling.
      let (first, last) = (location.offset, location.offset + location.len - 1)
      let characters = Array(scanner.peeker.source)
      return String(characters[first...last])
    }
  }
}
