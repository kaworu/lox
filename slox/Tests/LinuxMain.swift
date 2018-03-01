import XCTest

import ScannerTests
import ParserTests
import EvaluationTests

var tests = [XCTestCaseEntry]()
tests += ScannerTests.allTests()
tests += ParserTests.allTests()
tests += EvaluationTests.allTests()
XCTMain(tests)
