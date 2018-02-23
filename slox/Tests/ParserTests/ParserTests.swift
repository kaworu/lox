import XCTest
@testable import Lox

class ParserTests: XCTestCase {
  func testDummy() {
    XCTAssertEqual(1, 1)
  }
}

#if os(Linux)
extension ParserTests {
  static var allTests: [(String, (ParserTests) -> () throws -> Void)] {
    return [
      ("dummy", testDummy),
    ]
  }
}
#endif // os(Linux)
