import Result

// Lox Scanner, lex a string into a stream of tokens.
class Scanner: IteratorProtocol {
  // Run the scanner on the given lox source and return an array of token or an
  // array of error (boxed in a bin).
  static func scan(source: String) -> Result<[Token], Error.Bin> {
    var tokens: [Token] = []
    var errors: [Error] = []
    let scanner = Scanner(source: source)
    while let result = scanner.next() {
      switch result {
        case let .failure(err):
          errors.append(err)
        case let .success(token):
          tokens.append(token)
      }
    }
    if errors.isEmpty {
      return .success(tokens)
    } else {
      return .failure(Error.Bin(content: errors))
    }
  }

  let characters: [Character]
  var peeker: Peeker

  // Create a new scanner from a source input sting.
  init(source: String) {
    self.characters = Array(source)
    self.peeker = Peeker(source)
  }

  // Return the next token scanned or an a error on failure. If the end of
  // input is reached, nil is returned.
  func next() -> Result<Token, Error>? {
    // Returns true if the given character is blank, false otherwise.
    func is_blank(_ c: Character) -> Bool {
      return c == " " || c == "\t" || c == "\r" || c == "\n"
    }

    // Returns true if the given character is a digit, false otherwise.
    func is_digit(_ c: Character) -> Bool {
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
    // Check for the end of input.
    guard let c = peeker.next() else { return nil }

    // Helper to create a successfully scanned token.
    func token(_ kind: Token.Kind) -> Result<Token, Error> {
      let len = peeker.offset - c.offset;
      let token = Token(kind: kind, location: (c.offset, len), scanner: self)
      return .success(token)
    }

    // Helper to create an error that failed to scan.
    func error(_ kind: Error.Kind) -> Result<Token, Error> {
      let len = peeker.offset - c.offset;
      let error = Error(kind: kind, location: (c.offset, len), scanner: self)
      return .failure(error)
    }

    // Scan a literal string. Can return a failure if the end of input is
    // reached before finding a closing double quote.
    func string() -> Result<Token, Error> {
      // XXX: no way to escape double quote in a string (i.e. `"')
      let content = peeker.skip(while: { $0 != "\"" })
      // Here we are on the closing double quote or at EOF.
      guard peeker.advance() else {
        return error(.unterminated_string)
      }
      return token(.string(String(content)))
    }

    // Scan a literal number, always succeed.
    func number() -> Result<Token, Error> {
      var digits = [c.element] + peeker.skip(while: is_digit)
      let maybe_dot   = peeker.peek()?.element
      let maybe_digit = peeker.peek2()?.element
      if maybe_dot == "." && is_digit(maybe_digit ?? "?") {
        digits.append(peeker.next()!.element) // the dot
        digits.append(contentsOf: peeker.skip(while: is_digit))
      }
      let n = Double(String(digits))!
      return token(.number(n))
    }

    // Scan an identifier or a keyword, always succeed.
    func identifier() -> Result<Token, Error> {
      let chars = [c.element] + peeker.skip(while: is_alnum)
      let word  = String(chars)
      let kind  = Token.Kind.keywords[word] ?? .identifier(word)
      return token(kind)
    }

    // Skip the input until we find a blank character and create an error
    // containing the skipped characters, always return a `.failure'.
    func unkown() -> Result<Token, Error> {
        let chars = peeker.skip(while: { !is_blank($0) })
        return error(.unknown_stuff(String(chars)))
    }

    // Skip the input until we find a newline and returns the next token
    // (if any).
    func comment() -> Result<Token, Error>? {
      // A line comment goes until the end of the line.
      peeker.skip(while: { $0 != "\n" })
      return self.next()
    }

    switch c.element {
      case "(": return token(.open_paren)
      case ")": return token(.close_paren)
      case "{": return token(.open_brace)
      case "}": return token(.close_brace)
      case ",": return token(.comma)
      case ".": return token(.dot)
      case "-": return token(.minus)
      case "+": return token(.plus)
      case ";": return token(.semi_colon)
      case "*": return token(.star)
      case "!": return peeker.match("=") ? token(.ne)  : token(.bang)
      case "=": return peeker.match("=") ? token(.eq)  : token(.assign)
      case ">": return peeker.match("=") ? token(.gte) : token(.gt)
      case "<": return peeker.match("=") ? token(.lte) : token(.lt)
      case "/": return peeker.match("/") ? comment()   : token(.slash)
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

    let s: String
    var chars: EnumeratedIterator<String.Iterator>
    var lookahead: (Element?, Element?)

    // Create an iterator from a given String.
    init(_ s: String) {
      self.s = s
      self.chars = s.enumerated().makeIterator()
      self.lookahead = (self.chars.next(), self.chars.next())
    }

    // Returns the next character without consuming it.
    func peek() -> Element? {
      return lookahead.0
    }

    // Returns the character after next character without consuming it.
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
      return peek()?.offset ?? s.count
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
      case ne          // `!='
      case assign      // `='
      case eq          // `=='
      case gt          // `>'
      case gte         // `>='
      case lt          // `<'
      case lte         // `<='
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
      let (first, last) = (location.offset, location.offset + location.len - 1)
      return String(scanner.characters[first...last])
    }
  }

  // Error are lexemes that are not token. In other words they are invalid
  // and, as a result, errors.
  struct Error: Swift.Error {
    // A wrapper around `[Error]' because Result.Error type need something that
    // conform to Swift.Error. We can't make `[Error]' conform to Swift.Error,
    // see https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md
    struct Bin: Swift.Error {
      let content: [Error]
    }

    // Type of Scanner Error.
    enum Kind {
      case unterminated_string
      case unknown_stuff(String)
    }
    let kind: Kind
    let location: (offset: Int, len: Int)
    let scanner: Scanner
  }
}
