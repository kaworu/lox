import XCTest
@testable import ScannerTests
@testable import ParserTests

XCTMain([
    testCase(ScannerTests.allTests),
    testCase(ParserTests.allTests),
])
