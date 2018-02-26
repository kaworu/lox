import XCTest

import ScannerTests
import ParserTests

var tests = [XCTestCaseEntry]()
tests += ScannerTests.allTests()
tests += ParserTests.allTests()
XCTMain(tests)
