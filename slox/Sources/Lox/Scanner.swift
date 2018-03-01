// Lox Scanner, lex a string into a stream of tokens.
class Scanner: Swift.Sequence {
  // Run the scanner on the given lox source and return an array of tokens.
  static func scan(src: Source) -> [Token] {
    return Array(Scanner(src: src))
  }

  let src: Source

  // Create a new scanner from a source input.
  init(src: Source) {
    self.src = src
  }

  // Conform to Sequence.
  func makeIterator() -> PeekableIterator {
    return PeekableIterator(self)
  }

  // Peekable iterator over scanner tokens, much like Source.PeekableIterator.
  class PeekableIterator: Swift.IteratorProtocol {
    typealias Element = Token

    let scanner: Scanner
    var peeker: Source.Iterator
    var lookahead: (Element?, Element?)

    // Create an iterator from its token scanner.
    init(_ scanner: Scanner) {
      self.scanner = scanner
      self.peeker = scanner.src.makeIterator()
      // initialize self.lookahead
      let _ = next()
      let _ = next()
    }

    // Returns the next token without consuming it.
    func peek() -> Element? {
      return lookahead.0
    }

    // Returns the token after next one without consuming it.
    func peek2() -> Element? {
      return lookahead.1
    }

    // Returns the next character and advance the iterator.
    func next() -> Element? {
      let ret = lookahead.0
      lookahead = (lookahead.1, scan())
      return ret
    }

    // Advance the iterator and return true if an element was consumed, false
    // otherwise.
    @discardableResult
    func advance() -> Bool {
      return next() != nil
    }

    // The lox source of our scanner.
    var src: Source {
      return scanner.src
    }

    // Return the next token scanned or nil if the end of input is reached.
    func scan() -> Token? {
      // Returns true if the given character is blank, false otherwise.
      func is_blank(_ c: Character) -> Bool {
        return c == " " || c == "\t" || c == "\r" || c == "\n"
      }

      // Returns true if the given character is not nil a digit, false
      // otherwise.  NOTE: we have the optional dance because of how number()
      // is implemented, see below.
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
        return Token(kind, location: src.location(at: c.offset, count: len)!)
      }

      // Scan a literal string. Can produce an .unterminated_string token if
      // the end of input is reached before finding a closing double quote.
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
        let chars = [c.element] + peeker.skip(while: { !is_blank($0) })
        return tokenize(.unknown_stuff(String(chars)))
      }

      // Skip the input until we find a newline and returns the next token
      // (if any).
      func comment() -> Token? {
        // A line comment goes until the end of the line.
        peeker.skip(while: { $0 != "\n" })
        return self.scan()
      }

      // main scanner switch.
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
  }
}
