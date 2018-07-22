import XCTest
@testable import SwiftLisp

final class SwiftLispTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    print([
      "(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))",
      "(+ 1 2)",
      "(+ a 3)",
      "(- 3 5)",
      "(1 2 3)",
      "(def a (+ 5 3)) (def b 5) (+ a b)",
      "(def f (fn (a b) (+ a a b))) (f 2 5)",
      "((fn (a b) (+ a b)) 2 5)",
      "(def f (fn (a b) (+ a (f a b)))) (f 2 5)"
    ])
    XCTAssertEqual("Hello, World!", "Hello, World!")
  }
  func runAssert<T>(input: String, expected: Result<T>) {
    let lexOutput = lex(input: input)
    let exprs = read(input: lexOutput)
  }

  static var allTests = [
    ("testExample", testExample)
  ]
}
