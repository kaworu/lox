import XCTest
import TestSupport

@testable import Lox

class ScannerTests: XCTestCase {
  // helper.
  func scan(file: String) {
    let source = TestSupport.read(file: file)!
    let expectations = TestSupport.output_expect(from: source)
    let tokens = Scanner.scan(source: source)
    let output = tokens.jloxDescription
    XCTAssertEqual(output, expectations)
  }

  func test_identifiers() {
    scan(file: "scanning/identifiers")
  }

  func test_keywords() {
    scan(file: "scanning/keywords")
  }

  func test_numbers() {
    scan(file: "scanning/numbers")
  }

  func test_punctuators() {
    scan(file: "scanning/punctuators")
  }

  func test_strings() {
    scan(file: "scanning/strings")
  }

  func test_whitespace() {
    scan(file: "scanning/whitespace")
  }

  static var allTests = [
    ("identifiers", test_identifiers),
    ("keywords",    test_keywords),
    ("numbers",     test_numbers),
    ("punctuators", test_punctuators),
    ("strings",     test_strings),
    ("whitespace",  test_whitespace),
  ]
}
