import Foundation

// Lox source code (file) wrapper.
public class Source: Swift.Sequence {
  let id: String // usually the source code file path
  let content: String
  let lines: [String]
  let characters: [Character]

  // Create a source reading the given path file content as UTF-8.
  public convenience init(path: String) throws {
    guard let data = FileManager.default.contents(atPath: path) else {
      throw Error.read_failed(path: path)
    }
    guard let decoded = String(data: data, encoding: .utf8) else {
      throw Error.decoding_failed(path: path, content: data)
    }
    self.init(id: path, content: decoded)
  }

  // Create a source given its id and content.
  public init(id: String, content: String) {
    self.id = id
    self.content = content
    self.lines = content.split(separator: "\n").map(String.init)
    self.characters = Array(content)
  }

  // Returns a peekable iterator over this source characters.
  public func makeIterator() -> PeekableIterator {
    return PeekableIterator(self)
  }

  // Return a location in this source starting at the given offset of `count'
  // characters long.
  public func location(at offset: Int, count: Int) -> Location? {
    return Location(in: self, at: offset, count: count)
  }

  // Represents a location in a source. Conceptually a substring of the
  // source's content.
  // FIXME: Can only be used for a valid location (e.g. for a token), can't be
  // used for end of the line or end of file etc.
  public struct Location: Swift.CustomStringConvertible {
    let offset: Int
    let count: Int
    let src: Source

    // Create a new location in the given source, returns nil if either `at' or
    // `count' is out of bounds wrt the source's content.
    init?(in src: Source, at: Int, count: Int) {
      guard at >= 0 && count >= 0 else { return nil }
      guard (at + count) <= src.characters.count else { return nil }
      self.src = src
      self.offset = at
      self.count = count
    }

    // The substring in the source's content that is represented by this
    // location.
    public var description: String {
      let (first, last) = (offset, offset + count - 1)
      return String(src.characters[first...last])
    }
  }

  // Peekable iterator over enumerated string characters.
  public class PeekableIterator: Swift.IteratorProtocol {
    public typealias Element = (offset: Int, element: Character)

    let src: Source
    var chars: EnumeratedIterator<String.Iterator>
    var lookahead: (Element?, Element?)

    // Create an iterator from a given String.
    init(_ src: Source) {
      self.src = src
      self.chars = src.content.enumerated().makeIterator()
      self.lookahead = (self.chars.next(), self.chars.next())
    }

    // Returns the next character without consuming it.
    public func peek() -> Element? {
      return lookahead.0
    }

    // Returns the character after next one without consuming it.
    public func peek2() -> Element? {
      return lookahead.1
    }

    // Returns the next character and advance the iterator.
    public func next() -> Element? {
      let ret = lookahead.0
      lookahead = (lookahead.1, chars.next())
      return ret
    }

    // Advance the iterator and return true if an element was consumed, false
    // otherwise.
    @discardableResult
    public func advance() -> Bool {
      return next() != nil
    }

    // Returns true and consume the next character if it is the expected one,
    // returns false otherwise.
    public func match(_ expected: Character) -> Bool {
      if peek()?.element == expected {
        advance()
        return true
      } else {
        return false
      }
    }

    // Skip characters while the given predicate closure return true. Returns
    // all the skipped characters.
    @discardableResult
    public func skip(while predicate: (Character) -> Bool) -> [Character] {
      var chars: [Character] = []
      while let c = peek() {
        guard predicate(c.element) else { break }
        chars.append(c.element)
        advance()
      }
      return chars
    }

    // The offset of the peekable character, or src.content.count when we're at
    // the end of the string.
    public var offset: Int {
      return peek()?.offset ?? src.content.count
    }
  }

  // Error related to reading source files.
  public enum Error: Swift.Error {
    case read_failed(path: String)
    case decoding_failed(path: String, content: Data)
  }
}
