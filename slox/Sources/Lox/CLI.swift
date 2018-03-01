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
  public func main(_ argv: [String]) throws -> Int32 {
    if argv.isEmpty {
      return try repl()
    } else {
      return try execute(path: argv[0], argv: Array(argv[1...]))
    }
  }

  // Lox Run Eval Print Loop. Returns the process exit status.
  func repl() throws -> Int32 {
    // magic keystroke combination to exit the repl.
    let quit = ":q" // vi-friendly, `:' is not used by lox.
    // the repl prompt.
    let prompt = "\(progname)> "

    // Show the prompt.
    func show_prompt() {
      print(prompt, terminator: "")
      fflush(stdout)
    }

    // Display a welcome banner.
    func welcome() {
      print("Welcome to lox. Type \(quit) or Control-C to exit.")
    }

    welcome()
    show_prompt()
    while let line = readLine() {
      guard line != quit else { break }
      do {
        let src = Source(id: "<repl>", content: line)
        let value = try Interpreter.interpret(code: src)
        print("=> \(value)")
      } catch let error as DiagnosisConvertible {
        let indent = String(repeating: " ", count: prompt.count)
        let diagnosis = error.diagnosis()
        let (_, _, marker) = diagnosis.info()
        let padding = String(repeating: " ", count: marker)
        print(indent + padding + "^")
        print("\(diagnosis.type): \(diagnosis.msg)")
      }
      show_prompt()
    }
    return 0 // success
  }

  // Execute the lox source file at the given path. Returns the process exit
  // status.
  func execute(path: String, argv: [String]) throws -> Int32 {
    do {
      let src = try Source(path: path)
      let _ = try Interpreter.interpret(code: src)
    } catch Source.Error.read_failed {
      err("\(path): read failed")
      return -1
    } catch Source.Error.decoding_failed {
      err("\(path): decoding failed (is it an UTF-8 encoded file?)")
      return -1
    }
    return 0 // success
  }

  // Print the given message and a trailing newline on stderr.
  func err(_ msg: String) {
    fputs(msg + "\n", stderr)
  }
}
