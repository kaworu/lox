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

  func identifiers() {
    scan(file: "scanning/identifiers")
  }

  func keywords() {
    scan(file: "scanning/keywords")
  }

  func numbers() {
    scan(file: "scanning/numbers")
  }

  func punctuators() {
    scan(file: "scanning/punctuators")
  }

  func strings() {
    scan(file: "scanning/strings")
  }

  func whitespace() {
    scan(file: "scanning/whitespace")
  }

  static var allTests = [
    ("identifiers", identifiers),
    ("keywords",    keywords),
    ("numbers",     numbers),
    ("punctuators", punctuators),
    ("strings",     strings),
    ("whitespace",  whitespace),
  ]
}
