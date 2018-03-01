// Expression produced by the parser.
class Expression {
  // Terminal expression that can be produced.
  enum Value: Swift.CustomStringConvertible {
    case `nil`
    case string(String)
    case number(Double)
    case Boolean(Bool)

    // Conform to CustomStringConvertible.
    var description: String {
      switch self {
        case .nil:            return "nil"
        case let .string(s):  return "\"\(s)\""
        case let .number(n):  return "\(n)"
        case let .Boolean(b): return "\(b)"
      }
    }

    // A string description of this value type.
    var type: String {
      switch self {
        case .nil:     return "nil"
        case .string:  return "string"
        case .number:  return "number"
        case .Boolean: return "Boolean"
      }
    }
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
    case literal(Value)
    case identifier(String)
    case grouping(Expression)
    case unary(op: Prefix, rhs: Expression)
    case binary(lhs: Expression, op: Infix, rhs: Expression)
  }

  let kind: Kind
  let tokens: [Scanner.Token]
  weak var parent: Expression? = nil

  // Create an expression given its kind and its tokens. Because expressions
  // are created "bottom-up" `parent' (it's recursive through its kind) should
  // be set afterwards.
  init(_ kind: Kind, tokens: [Scanner.Token]) {
    self.kind = kind
    self.tokens = tokens
  }
}
