// Simple wrapper around the main entry point of Lox CLI.

import Foundation // for exit()
import Lox

let progname = CommandLine.arguments[0] // NOTE: unused
let argv     = CommandLine.arguments[1...]
let retval   = CLI().main(Array(argv))
exit(retval)
