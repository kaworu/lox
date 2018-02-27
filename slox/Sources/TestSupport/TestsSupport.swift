import Foundation
import Regex

// Some handy helper static methods for tests. Mostly reading and parsing the
// test files used by the original craftinginterpreters.com project that we
// have as a git submodule.
// NOTE: enum without case so that there can't be instance of TestSupport.
public enum TestSupport {

  // Returns the content of the provided craftinginterpreters test file, or nil
  // on failure.
  public static func read(file: String) throws -> String {
    let path = try Dir.craftinginterpreters(test: file)
    guard let content = FileManager.default.contents(atPath: path) else {
      throw Error.read_failed(file: path)
    }
    guard let decoded = String(data: content, encoding: .utf8) else {
      throw Error.decoding_failed(file: path)
    }
    return decoded
  }

  // FIXME: needs a proper abstraction once we get to other expectation types.
  public static func output_expect(from: String) -> [String] {
    let output_expect_re = Regex("// expect: ?(.*)")
    var expectations: [String] = []
    let lines = from.split(separator: "\n").map(String.init)
    for line in lines {
      if let match = output_expect_re.firstMatch(in: line) {
        expectations.append(match.captures[0]!)
      }
    }
    return expectations
  }

  // Directory helper "module".
  enum Dir {
    // Capture the root project directory assuming we're running the test.
    static let PROJECT_DIR_RE = Regex("^(/.+)/slox/\\.build/[^/]+/debug/LoxPackageTests\\.xctest$")

    // Returns the project directory. Returns nil if we're not running
    // LoxPackageTests.xctest.
    static func project() throws -> String {
      let xctest = CommandLine.arguments[0]
      guard let match = Dir.PROJECT_DIR_RE.firstMatch(in: xctest) else {
        throw Error.unrecognized_command_line(xctest)
      }
      return match.captures[0]!
    }

    // Returns the absolute path of the given craftinginterpreters test file,
    // or nil on failure.
    static func craftinginterpreters(test: String) throws -> String {
      let root = try Dir.project()
      let path = "\(root)/craftinginterpreters/test/\(test).lox"
      return path
    }
  }

  enum Error: Swift.Error {
    case read_failed(file: String)
    case decoding_failed(file: String)
    case unrecognized_command_line(String)
  }
}
