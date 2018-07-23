import XCTest
@testable import SwiftLisp

final class SwiftLispTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    let testPrograms = ["(+ 1 2)"]

    zip(testPrograms, results).forEach { tup in
       let program = tup.0
       let expected = tup.1
      let lexOutput = lex(input: program)
      let exprs: [Expr] = read(input: lexOutput)
      let result: Result<Expr> = eval(exprs)
      print("hello")
      result.forEach { (valueExpr: Expr) in
        //XCTAssertEqual(valueExpr, expected)
      }
    }
  }

  static var allTests = [
    ("testExample", testExample)
  ]
}
