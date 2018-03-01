import XCTest
import TestSupport

@testable import Lox

class EvaluationTests: XCTestCase {
  // helper.
  func eval(file: String) throws {
    let path = try TestSupport.path(of: file)
    let src = try Lox.Source(path: path)
    let expectations = TestSupport.output_expect(from: src.content)
    let expectation = expectations.first!
    let expression = try Lox.Parser.parse(src: src)
    do {
      let value = try expression.evaluate()
      let output = value.jloxDescription
      XCTAssertEqual(output, expectation)
    } catch let err as Interpreter.Error {
      XCTFail("\(err)")
    }
  }

  func test_evaluate() throws {
    try eval(file: "expressions/evaluate")
  }

  static var allTests = [
    ("evaluate", test_evaluate),
  ]
}
