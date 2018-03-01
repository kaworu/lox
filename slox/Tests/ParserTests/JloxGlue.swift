@testable import Lox

// Expression description as jlox display them.

extension Lox.Expression {
  var jloxDescription: String {
    switch self.kind {
      case let .identifier(id):
        return "\(id)"
      case let .literal(value):
        return "\(value)"
      case let .grouping(expr):
        return "(group \(expr.jloxDescription))"
      case let .unary(_, rhs):
        return "(\(tokens.first!.lexeme) \(rhs.jloxDescription))"
      case let .binary(lhs, _, rhs):
        return "(\(tokens.first!.lexeme) \(lhs.jloxDescription) \(rhs.jloxDescription))"
    }
  }
}
