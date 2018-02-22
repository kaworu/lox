import Foundation

// Lox Command Line Interface goo.
public class CLI {
  // The CLI program name.
  let progname: String

  // Create a new CLI given its program name.
  public init(_ progname: String = "lox") {
    self.progname = progname
  }

  // CLI single entry point. Launch the REPL if argv is empty, or assume that
  // the first element in argv is a path to a lox source file to execute.
  // Returns the process exit status.
  public func main(_ argv: [String]) -> Int32 {
    if argv.isEmpty {
      return repl()
    } else {
      return execute(path: argv[0], argv: Array(argv[1...]))
    }
  }

  // Lox Run Eval Print Loop. Returns the process exit status.
  func repl() -> Int32 {
    // magic keystroke combination to exit the repl.
    let quit = ":q" // vi-friendly, `:' is not used by lox.

    // Display a welcome banner.
    func welcome() {
      print("Welcome to lox. Type \(quit) or Control-C to exit.")
    }

    // Show the prompt.
    func prompt() {
      print("\(progname)> ", terminator: "")
      fflush(stdout)
    }

    welcome()
    prompt()
    while let line = readLine() {
      guard line != quit else { break }
      let obj = run(source: line)
      print("=> \(obj.debugDescription)")
      prompt()
    }
    return 0 // success
  }

  // Execute the lox source file at the given path. Returns the process exit
  // status.
  func execute(path: String, argv: [String]) -> Int32 {
    guard let source = readfile(path: path) else { return -1 }
    let obj = run(source: source)
    print("=> \(obj.debugDescription)")
    return 0 // success
  }

  // Returns the given path file content as UTF-8 or nil on error.
  func readfile(path: String) -> String? {
    guard let content = FileManager.default.contents(atPath: path) else {
      err("\(path): read failed")
      return nil
    }
    guard let decoded = String(data: content, encoding: .utf8) else {
      err("\(path): decoding failed (is it an UTF-8 encoded file?)")
      return nil
    }
    return decoded
  }

  // Run the given lox code.
  // FIXME: should return the AST or something.
  func run(source: String) -> String {
    print("source: \(source)")
    return Scanner.scan(source: source).debugDescription
  }

  // Print the given message and a trailing newline on stderr.
  func err(_ msg: String) {
    fputs(msg + "\n", stderr)
  }
}
