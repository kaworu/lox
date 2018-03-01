extension Scanner {
  // What the scanner attempt to produce from a lox source.
  struct Token {
    let kind: Kind
    let location: Source.Location

    // Create a new token of the given kind at the provided location.
    init(_ kind: Kind, location: Source.Location) {
      self.kind = kind
      self.location = location
    }

    // The substring in the source that is matched by this token.
    var lexeme: String {
      return "\(self.location)"
    }

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
  }
}
