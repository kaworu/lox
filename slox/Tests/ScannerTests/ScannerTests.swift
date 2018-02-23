import XCTest
import Regex
@testable import Lox

protocol JloxStringConvertible {
  var jloxDescription: String { get }
}

func jlox_fmt(_ tokens: [Lox.Scanner.Token]) -> [String] {
  return tokens.map { $0.jloxDescription } + ["EOF  null"]
}

extension Lox.Scanner.Token: JloxStringConvertible {
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
      case .ne:
        return "BANG_EQUAL \(lexeme) null"
      case .assign:
        return "EQUAL \(lexeme) null"
      case .eq:
        return "EQUAL_EQUAL \(lexeme) null"
      case .gt:
        return "GREATER \(lexeme) null"
      case .gte:
        return "GREATER_EQUAL \(lexeme) null"
      case .lt:
        return "LESS \(lexeme) null"
      case .lte:
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
    }
  }
}

func read_test(file: String) -> String {
  let path_re = Regex("^(/.+)/slox/\\.build/[^/]+/debug/LoxPackageTests\\.xctest$")
  let xctest = CommandLine.arguments[0]
  let root = path_re.firstMatch(in: xctest)!.captures[0]!
  let testdir = "\(root)/craftinginterpreters/test"
  let path = "\(testdir)/\(file).lox"
  let content = FileManager.default.contents(atPath: path)!
  let decoded = String(data: content, encoding: .utf8)!
  return decoded
}

func output_expect(from: String) -> [String] {
  let output_expect_re = Regex("// expect: ?(.*)")
  var expectations: [String] = []
  let lines = from.split(separator: "\n").map(String.init)
  for line in lines {
    if let match = output_expect_re.firstMatch(in: line) {
      expectations.append(match.captures[0]!)
    }
  }
  return expectations
}

class ScannerTests: XCTestCase {
  // helper.
  func test(file: String) {
    let source = read_test(file: file)
    let expectations = output_expect(from: source)
    switch Scanner.scan(source: source) {
      case let .success(tokens):
        let to_check = jlox_fmt(tokens)
        XCTAssertEqual(to_check.count, expectations.count)
        XCTAssertEqual(to_check, expectations)
      case let failure:
        XCTFail("\(failure)")
    }
  }

  func identifiers() {
    test(file: "scanning/identifiers")
  }

  func keywords() {
    test(file: "scanning/keywords")
  }

  func numbers() {
    test(file: "scanning/numbers")
  }

  func punctuators() {
    test(file: "scanning/punctuators")
  }

  func strings() {
    test(file: "scanning/strings")
  }

  func whitespace() {
    test(file: "scanning/whitespace")
  }
}

#if os(Linux)
extension ScannerTests {
  static var allTests: [(String, (ScannerTests) -> () throws -> Void)] {
    return [
      ("identifiers", identifiers),
      ("keywords",    keywords),
      ("numbers",     numbers),
      ("punctuators", punctuators),
      ("strings",     strings),
      ("whitespace",  whitespace),
    ]
  }
}
#endif // os(Linux)
