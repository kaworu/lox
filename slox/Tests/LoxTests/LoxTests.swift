import XCTest
@testable import Lox

class LoxTests: XCTestCase {
  func testDummy() {
    XCTAssertEqual(1, 1)
  }
}

#if os(Linux)
extension LoxTests {
  static var allTests: [(String, (LoxTests) -> () throws -> Void)] {
    return [
      ("dummy", testDummy),
    ]
  }
}
#endif // os(Linux)
