import Result

// Lox Parser, produce an AST from a source string.
class Parser {
  typealias ParseFunc = () throws -> Expression
  typealias InfixMatcher  = (Scanner.Token.Kind) -> Expression.Infix?
  typealias PrefixMatcher = (Scanner.Token.Kind) -> Expression.Prefix?

  // Run the parser on the given lox source and return an expression.
  static func parse(source: String) throws -> Expression {
    let parser = Parser(source: source)
    return try parser.expression()
  }

  var peeker: Peeker

  // Create a new parser from a source input string.
  init(source: String) {
    self.peeker = Peeker(source)
  }

  // Parse an expression or throw an Error on failure.
  func expression() throws -> Expression {
    return try equality()
  }

  // equality → comparison ( ( "!=" | "==" ) comparison )* ;
  func equality() throws -> Expression {
    return try infix_binary(higher: comparison) {
      switch $0 {
        case .bang_eq: return .ne
        case .eq_eq:   return .eq
        default:       return nil
      }
    }
  }

  // comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;
  func comparison() throws -> Expression {
    return try infix_binary(higher: addition) {
      switch $0 {
        case .gt:    return .gt
        case .gt_eq: return .gte
        case .lt:    return .lt
        case .lt_eq: return .lte
        default:     return nil
      }
    }
  }

  // addition → multiplication ( ( "-" | "+" ) multiplication )* ;
  func addition() throws -> Expression {
    return try infix_binary(higher: multiplication) {
      switch $0 {
        case .minus: return .sub
        case .plus:  return .add
        default:     return nil
      }
    }
  }

  // multiplication → unary ( ( "-" | "+" ) unary )* ;
  func multiplication() throws -> Expression {
    return try infix_binary(higher: unary) {
      switch $0 {
        case .slash: return .div
        case .star:  return .mult
        default:     return nil
      }
    }
  }

  // unary → ( "!" | "-" ) unary | primary ;
  func unary() throws -> Expression {
    return try prefix_unary(this: unary, higher: primary) {
      switch $0 {
        case .bang:  return .not
        case .minus: return .inverse
        default:     return nil
      }
    }
  }

  // primary → NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")" ;
  func primary() throws -> Expression {
    // Helper to "translate" a scanner token kind to an expression literal.
    func literal(_ from: Scanner.Token.Kind) -> Expression.Literal? {
      switch from {
        case .identifier(let id): return .identifier(id)
        case .string(let s):      return .string(s)
        case .number(let n):      return .number(n)
        case .false:              return .Boolean(false)
        case .true:               return .Boolean(true)
        case .nil:                return .nil
        default:                  return nil
      }
    }

    // eat the next token.
    guard let token = peeker.next() else {
      throw Error.expected_expression(got: nil)
    }

    // Helper parsing a grouped expression.
    func grouped(open: Scanner.Token) throws -> Expression {
      let expr = try expression()
      let maybe_close_paren = peeker.next()
      guard case .close_paren? = maybe_close_paren?.kind else {
        throw Error.grouping(open: open, expr, not_close: maybe_close_paren)
      }
      let tokens = [open, maybe_close_paren!]
      return Expression(.grouping(expr), tokens: tokens, parser: self)
    }

    if case .open_paren = token.kind {
      return try grouped(open: token)
    } else if let lit = literal(token.kind) {
      return Expression(.literal(lit), tokens: [token], parser: self)
    } else {
      throw Error.expected_expression(got: token)
    }
  }

  // helper to parse an infix binary operation.
  func infix_binary(higher: ParseFunc, match: InfixMatcher)
      rethrows -> Expression {
    var lhs = try higher()
    while let peeked = peeker.peek() {
      guard let op = match(peeked.kind) else { break }
      let token = peeker.next()! // eat the matched operator token
      let rhs = try higher()
      let kind: Expression.Kind = .binary(lhs: lhs, op: op, rhs: rhs)
      let expr = Expression(kind, tokens: [token], parser: self)
      (lhs.parent, rhs.parent) = (expr, expr)
      lhs = expr
    }
    return lhs
  }

  // helper to parse a prefix unary operation.
  func prefix_unary(this: ParseFunc, higher: ParseFunc, match: PrefixMatcher)
      rethrows -> Expression {
    if let peeked = peeker.peek() {
      if let op = match(peeked.kind) {
        let token = peeker.next()! // eat the matched operator token
        let rhs = try this()
        let kind: Expression.Kind = .unary(op: op, rhs: rhs)
        let expr = Expression(kind, tokens: [token], parser: self)
        rhs.parent = expr
        return expr
      }
    }
    return try higher()
  }

  // Discard tokens until a statement boundary is found.
  func synchronize() {
    sync_loop: while let token = peeker.next() {
      if case .semi_colon = token.kind {
        guard let next = peeker.peek() else { break }
        switch next.kind {
          case .class, .fun, .var, .for, .if, .while, .print, .return:
            break sync_loop
          default:
            break
        }
      }
    }
  }

  // Peekable iterator over scanner tokens, much like Scanner.Peeker.
  class Peeker: IteratorProtocol {
    typealias Element = Scanner.Token

    let source: String
    var scanner: Scanner
    var lookahead: (Element?, Element?)

    // Create an iterator from a given String.
    init(_ source: String) {
      self.source = source
      self.scanner = Scanner(source: source)
      self.lookahead = (self.scanner.next(), self.scanner.next())
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
      lookahead = (lookahead.1, scanner.next())
      return ret
    }

    // Advance the iterator and return true if an element was consumed, false
    // otherwise.
    @discardableResult
    func advance() -> Bool {
      return next() != nil
    }
  }

  // Expression produced by the parser.
  class Expression {
    // Terminal expression that can be produced.
    enum Literal {
      case identifier(String)
      case string(String)
      case number(Double)
      case Boolean(Bool)
      case `nil`
    }

    // Unary prefix operators.
    enum Prefix {
      case not, inverse
    }

    // Binary infix operators.
    enum Infix {
      case eq, ne, lt, lte, gt, gte
      case add, sub, mult, div
    }

    // Type of Expression.
    indirect enum Kind {
      case literal(Literal)
      case grouping(Expression)
      case unary(op: Prefix, rhs: Expression)
      case binary(lhs: Expression, op: Infix, rhs: Expression)
    }

    let kind: Kind
    let tokens: [Scanner.Token]
    let parser: Parser
    weak var parent: Expression? = nil

    init(_ kind: Kind, tokens: [Scanner.Token], parser: Parser) {
      self.kind = kind
      self.tokens = tokens
      self.parser = parser
    }
  }

  // Errors produced by the parser.
  enum Error: Swift.Error {
      case grouping(open: Scanner.Token, Expression, not_close: Scanner.Token?)
      case expected_expression(got: Scanner.Token?)
  }
}
