@testable import Lox

// Expression description as jlox display them.

extension Lox.Expression.Value {
  var jloxDescription: String {
    func is_whole(_ number: Double) -> Bool {
      return number.truncatingRemainder(dividingBy: 1) == 0
    }
    switch self {
      case let .number(n) where is_whole(n):
        return "\(Int(n))"
      default:
        return "\(self)"
    }
  }
}
