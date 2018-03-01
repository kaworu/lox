// Very basic diagnosis for parsing and runtime errors.
public class Diagnosis {
  let location: Source.Location?
  public let src: Source
  public let type, msg: String

  // Create a diagnosis error from a source location.
  init(_ type: String, msg: String, location: Source.Location) {
    self.location = location
    self.src = location.src
    self.type = type
    self.msg = msg
  }

  // Create a diagnosis error from a source without a location, this is how we
  // handle EOF (not very pretty).
  init(_ type: String, msg: String, src: Source) {
    self.location = nil
    self.src = src
    self.type = type
    self.msg = msg
  }

  // Return the line, its number, and a marker offset of the offending stuff.
  public func info() -> (line: String, lineno: Int, marker: Int) {
    if let location = self.location {
      var marker = location.offset
      var lineno = 0
      while marker >= src.lines[lineno].count {
        marker -= src.lines[lineno].count
        lineno += 1
      }
      let line = src.lines[lineno]
      return (line: line, lineno: lineno, marker: marker)
    } else {
      let line = src.lines.last!
      let lineno = src.lines.count
      return (line: line, lineno: lineno, marker: line.count)
    }
  }
}

// Protocol used by anything on which we can run a diagnosis, so we may catch
// errors that we can display.
protocol DiagnosisConvertible {
  func diagnosis() -> Diagnosis;
}

// Parsing error diagnosis.
extension Parser.Error: DiagnosisConvertible {
  // Conform the DiagnosisConvertible.
  func diagnosis() -> Diagnosis {
    // Diagnosis message depending on the error kind.
    func msg() -> String {
      switch self.kind {
        case let .unclosed_grouping(_, _, token):
          let unexpected = token.map { "\($0.kind)" }
          return "expected `)' to close grouped expression, but got \(unexpected ?? "eof")"
        case let .expected_expression(token):
          let unexpected = token.map { "\($0.kind)" }
          return "expected an expression, but got \(unexpected ?? "eof")"
      }
    }

    // The offending token if any.
    func token() -> Scanner.Token? {
      switch self.kind {
        case let .unclosed_grouping(_, _, token):
          return token
        case let .expected_expression(token):
          return token
      }
    }

    if let token = token() {
      return Diagnosis("parsing error", msg: msg(), location: token.location)
    } else { // EOF is offending
      return Diagnosis("parsing error", msg: msg(), src: src)
    }
  }
}

// Runtime error diagnosis.
extension Interpreter.Error: DiagnosisConvertible {
  // Conform to DiagnosisConvertible.
  func diagnosis() -> Diagnosis {
    switch self {
      case let .binary_operands(expr, (lhs, rhs)):
        // NOTE: `+' in lox can be used for string concatenation too, so we
        // need to display a different expectation error message for addition.
        var expected: String {
          if case .binary(_, .add, _) = expr.kind {
            return "(number, number) or (string, string)"
          } else {
            return "(number, number)"
          }
        }
        let got = "(\(lhs.type), \(rhs.type))"
        let token = expr.tokens.first!
        let msg = "invalid operands for binary operator `\(token.lexeme)':" +
          " expected \(expected) but got \(got)"
        return Diagnosis("runtime error", msg: msg, location: token.location)
      case let .unary_operands(expr, computed):
        let expected = "(number)"
        let got = "(\(computed.type))"
        let token = expr.tokens.first!
        let msg = "invalid operands for unary operator `\(token.lexeme)':" +
          " expected \(expected) but got \(got)"
        return Diagnosis("runtime error", msg: msg, location: token.location)
    }
  }
}
