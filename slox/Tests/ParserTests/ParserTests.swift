import XCTest
import TestSupport

@testable import Lox

class ParserTests: XCTestCase {
  // helper.
  func parse(file: String) throws {
    let source = try TestSupport.read(file: file)
    let expectations = TestSupport.output_expect(from: source)
    let expectation = expectations.first!
    do {
      let expression = try Lox.Parser.parse(source: source)
      let output = expression.jloxDescription
      XCTAssertEqual(output, expectation)
    } catch let err as Parser.Error {
      XCTFail("\(err)")
    }
  }

  func test_expression() throws {
    try parse(file: "expressions/parse")
  }

  static var allTests = [
    ("expression", test_expression),
  ]
}
