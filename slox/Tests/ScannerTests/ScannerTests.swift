import XCTest
import TestSupport

@testable import Lox

class ScannerTests: XCTestCase {
  // helper.
  func scan(file: String) throws {
    let path = try TestSupport.path(of: file)
    let src = try Lox.Source(path: path)
    let expectations = TestSupport.output_expect(from: src.content)
    let tokens = Lox.Scanner.scan(src: src)
    let output = tokens.jloxDescription
    XCTAssertEqual(output, expectations)
  }

  func test_identifiers() throws {
    try scan(file: "scanning/identifiers")
  }

  func test_keywords() throws {
    try scan(file: "scanning/keywords")
  }

  func test_numbers() throws {
    try scan(file: "scanning/numbers")
  }

  func test_punctuators() throws {
    try scan(file: "scanning/punctuators")
  }

  func test_strings() throws {
    try scan(file: "scanning/strings")
  }

  func test_whitespace() throws {
    try scan(file: "scanning/whitespace")
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
