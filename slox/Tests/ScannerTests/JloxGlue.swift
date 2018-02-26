@testable import Lox


// Token description as jlox display them.
extension Lox.Scanner.Token {
  var jloxDescription: String {
    switch self.kind {
      case .open_paren:
        return "LEFT_PAREN \(lexeme) null"
      case .close_paren:
        return "RIGHT_PAREN \(lexeme) null"
      case .open_brace:
        return "LEFT_BRACE \(lexeme) null"
      case .close_brace:
        return "RIGHT_BRACE \(lexeme) null"
      case .comma:
        return "COMMA \(lexeme) null"
      case .dot:
        return "DOT \(lexeme) null"
      case .minus:
        return "MINUS \(lexeme) null"
      case .plus:
        return "PLUS \(lexeme) null"
      case .semi_colon:
        return "SEMICOLON \(lexeme) null"
      case .slash:
        return "SLASH \(lexeme) null"
      case .star:
        return "STAR \(lexeme) null"
      case .bang:
        return "BANG \(lexeme) null"
      case .bang_eq:
        return "BANG_EQUAL \(lexeme) null"
      case .eq:
        return "EQUAL \(lexeme) null"
      case .eq_eq:
        return "EQUAL_EQUAL \(lexeme) null"
      case .gt:
        return "GREATER \(lexeme) null"
      case .gt_eq:
        return "GREATER_EQUAL \(lexeme) null"
      case .lt:
        return "LESS \(lexeme) null"
      case .lt_eq:
        return "LESS_EQUAL \(lexeme) null"
      case .identifier:
        return "IDENTIFIER \(lexeme) null"
      case .string(let s):
        return "STRING \(lexeme) \(s)"
      case .number(let n):
        return "NUMBER \(lexeme) \(n)"
      case .and:
        return "AND \(lexeme) null"
      case .class:
        return "CLASS \(lexeme) null"
      case .else:
        return "ELSE \(lexeme) null"
      case .false:
        return "FALSE \(lexeme) null"
      case .fun:
        return "FUN \(lexeme) null"
      case .for:
        return "FOR \(lexeme) null"
      case .if:
        return "IF \(lexeme) null"
      case .nil:
        return "NIL \(lexeme) null"
      case .or:
        return "OR \(lexeme) null"
      case .print:
        return "PRINT \(lexeme) null"
      case .return:
        return "RETURN \(lexeme) null"
      case .super:
        return "SUPER \(lexeme) null"
      case .this:
        return "THIS \(lexeme) null"
      case .true:
        return "TRUE \(lexeme) null"
      case .var:
        return "VAR \(lexeme) null"
      case .while:
        return "WHILE \(lexeme) null"
      case .unterminated_string:
        return "UNTERMINATED-STRING \(lexeme) null"
      case .unknown_stuff:
        return "GARBAGE \(lexeme) null"
    }
  }
}

// Jlox has a EOF token that we don't use.
extension Array where Element == Lox.Scanner.Token {
  var jloxDescription: [String] {
    return self.map { $0.jloxDescription } + ["EOF  null"]
  }
}
