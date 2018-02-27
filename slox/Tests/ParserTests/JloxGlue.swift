@testable import Lox

// Expression description as jlox display them.

extension Lox.Parser.Expression.Literal {
  var jloxDescription: String {
    switch self {
      case .identifier(let id): return id
      case .string(let s):      return "\"\(s)\""
      case .number(let n):      return "\(n)"
      case .Boolean(let b):     return "\(b)"
      case .nil:                return "nil"
    }
  }
}

extension Lox.Parser.Expression {
  var jloxDescription: String {
    switch self.kind {
      case let .literal(lit):
        return lit.jloxDescription
      case let .grouping(expr):
        return "(group \(expr.jloxDescription))"
      case let .unary(_, rhs):
        return "(\(tokens.first!.lexeme) \(rhs.jloxDescription))"
      case let .binary(lhs, _, rhs):
        return "(\(tokens.first!.lexeme) \(lhs.jloxDescription) \(rhs.jloxDescription))"
    }
  }
}
