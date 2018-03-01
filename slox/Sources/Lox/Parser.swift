// Lox Parser, produce an AST from a source.
class Parser {
  typealias ParseFunc = () throws -> Expression
  typealias InfixMatcher  = (Scanner.Token.Kind) -> Expression.Infix?
  typealias PrefixMatcher = (Scanner.Token.Kind) -> Expression.Prefix?

  // Run the parser on the given lox source and return an expression.
  static func parse(src: Source) throws -> Expression {
    let parser = Parser(src: src)
    return try parser.expression() // FIXME: to complete
  }

  var peeker: Scanner.Iterator

  // Create a new parser from a lox source input.
  init(src: Source) {
    self.peeker = Scanner(src: src).makeIterator()
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
    // eat the next token.
    guard let token = peeker.next() else {
      throw error(.expected_expression(got: nil))
    }

    // Helper parsing a grouped expression.
    func grouped(open: Scanner.Token) throws -> Expression {
      let expr = try expression()
      let close = peeker.next()
      guard case .close_paren? = close?.kind else {
        throw error(.unclosed_grouping(open: open, expr, not_close: close))
      }
      let tokens = [open, close!]
      return Expression(.grouping(expr), tokens: tokens)
    }

    switch token.kind {
      case .open_paren:
        return try grouped(open: token)
      case .string(let s):
        return Expression(.literal(.string(s)), tokens: [token])
      case .number(let n):
        return Expression(.literal(.number(n)), tokens: [token])
      case .false:
        return Expression(.literal(.Boolean(false)), tokens: [token])
      case .true:
        return Expression(.literal(.Boolean(true)), tokens: [token])
      case .nil:
        return Expression(.literal(.nil), tokens: [token])
      default:
        throw error(.expected_expression(got: token))
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
      let expr = Expression(kind, tokens: [token])
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
        let expr = Expression(kind, tokens: [token])
        rhs.parent = expr
        return expr
      }
    }
    return try higher()
  }

  // Helper to create a parser error of the given kind.
  func error(_ kind: Error.Kind) -> Error {
    return Error(kind: kind, src: src)
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

  // The lox source that we attempt to parse.
  var src: Source {
    return peeker.src
  }

  // Errors produced by the parser.
  struct Error: Swift.Error {
    let kind: Kind
    let src: Source

    enum Kind {
      case unclosed_grouping(open: Scanner.Token, Expression, not_close: Scanner.Token?)
      case expected_expression(got: Scanner.Token?)
    }
  }
}
