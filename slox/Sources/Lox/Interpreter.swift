// Lox interpreter, evaluate an AST produced by the parser.
enum Interpreter {
  typealias Value = Expression.Value
  typealias NumberComputation = (Double, Double) -> Expression.Value

  // Parse the given source code and evaluate it. May throw Parser.Error or
  // Interpreter.Error.
  static func interpret(code: Source) throws -> Value {
    let expression = try Parser.parse(src: code)
    let value = try expression.evaluate()
    return value
  }

  // Error not visibile outside the Interpreter scope (conceptually). They are
  // thrown by "low-level" functions, the runtime should catch theses error and
  // transform them into more elaborate one with context so that they can be
  // inspected (see Diagnosis).
  enum InternalError: Swift.Error {
    // Thrown by operators (e.g. `+') when the operands are not compatible.
    case invalid_operands
  }

  // Error thrown by the Interpreter.
  enum Error: Swift.Error {
    case binary_operands(Expression, computed: (lhs: Value, rhs: Value))
    case unary_operands(Expression, computed: Value)
  }

  // Helper for math expression stuff.
  static func math(_ lhs: Value, _ rhs: Value, compute: NumberComputation)
      throws -> Value {
    guard case let (.number(l), .number(r)) = (lhs, rhs) else {
      throw Interpreter.InternalError.invalid_operands
    }
    return compute(l, r)
  }
}

// Add evaluate() to Expression for the Interpreter.
extension Expression {
  // Returns the value of this expression.
  func evaluate() throws -> Value {
    switch self.kind {
      case .identifier(let id):
        return .string("id=\(id)") // FIXME: to complete
      case .literal(let value):
        return value
      case .grouping(let expr):
        return try expr.evaluate()
      case let .unary(.not, expr):
        let value = try expr.evaluate()
        return !value
      case let .unary(.inverse, expr):
        let value = try expr.evaluate()
        do {
          return try -value
        } catch Interpreter.InternalError.invalid_operands {
          throw Interpreter.Error.unary_operands(self, computed: value)
        }
      case let .binary(lhs, op, rhs):
        let left  = try lhs.evaluate()
        let right = try rhs.evaluate()
        do {
          switch op {
            case .eq:   return     left == right
            case .ne:   return     left != right
            case .lt:   return try left < right
            case .lte:  return try left <= right
            case .gt:   return try left > right
            case .gte:  return try left >= right
            case .add:  return try left + right
            case .sub:  return try left - right
            case .mult: return try left * right
            case .div:  return try left / right
          }
        } catch Interpreter.InternalError.invalid_operands {
          let computed = (lhs: left, rhs: right)
          throw Interpreter.Error.binary_operands(self, computed: computed)
        }
    }
  }
}

extension Expression.Value {
  // True if this value is "truthy", false otherwise.
  var is_truthy: Bool {
    switch self {
      case .nil:            fallthrough
      case .Boolean(false): return false
      default:              return true
    }
  }
}

// Define many operators for Expression.Value

prefix func ! (val: Expression.Value) -> Expression.Value {
  return .Boolean(val.is_truthy ? false : true)
}

prefix func - (val: Expression.Value) throws -> Expression.Value {
  return try .number(0) - val
}

func == (lhs: Expression.Value, rhs: Expression.Value) -> Expression.Value {
  func is_equal() -> Bool {
    switch (lhs, rhs) {
      case (.nil, .nil):
        return true
      case let (.string(l), .string(r)) where l == r:
        return true
      case let (.number(l), .number(r)) where l == r:
        return true
      case let (.Boolean(l), .Boolean(r)) where l == r:
        return true
      default:
        return false
    }
  }
  return .Boolean(is_equal())
}

func != (lhs: Expression.Value, rhs: Expression.Value) -> Expression.Value {
  return !(lhs == rhs)
}

func < (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
  return try Interpreter.math(lhs, rhs) { .Boolean($0 < $1) }
}

func <= (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
  return try Interpreter.math(lhs, rhs) { .Boolean($0 <= $1) }
}

func > (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
  return try Interpreter.math(lhs, rhs) { .Boolean($0 > $1) }
}

func >= (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
  return try Interpreter.math(lhs, rhs) { .Boolean($0 >= $1) }
}

// NOTE: Addition is a special case since it can be used for string
// concatenation.
func + (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
  if case let (.string(l), .string(r)) = (lhs, rhs) {
      return .string(l + r)
  } else {
    return try Interpreter.math(lhs, rhs) { .number($0 + $1) }
  }
}

func - (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
    return try Interpreter.math(lhs, rhs) { .number($0 - $1) }
}

func * (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
    return try Interpreter.math(lhs, rhs) { .number($0 * $1) }
}

func / (lhs: Expression.Value, rhs: Expression.Value) throws -> Expression.Value {
    return try Interpreter.math(lhs, rhs) { .number($0 / $1) }
}
