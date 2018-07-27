import XCTest
@testable import SwiftLispLib

final class SwiftLispTests: XCTestCase {
  static let testProgramsAndValues = [
    ("(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))", Result.value(Expr.number(186))),
    ("(+ 1 2)", Result.value(Expr.number(3))),
    ("(+ a 3)", Result.error("Variable not found: a")),
    ("(- 3 5)", Result.value(Expr.number(-2))),
    ("(1 2 3)", Result.error("Head of list is not a function, 1 in list (1 2 3)")),
    ("(def a (+ 5 3)) (def b 5) (+ a b)", Result.value(Expr.number(13))),
    ("(def f (fn (a b) (+ a a b))) (f 2 5)", Result.value(Expr.number(9))),
    ("((fn (a b) (+ a b)) 2 5)", Result.value(Expr.number(7))),
    ("(def negate (fn (a) (- a a a))) (negate 5)", Result.value(Expr.number(-5))),
    (
      "(def negate (fn (a) (- a a a))) (def add (fn (a b) (+ a b))) (add (negate 5) (negate 3))",
      Result.value(Expr.number(-8))
      ),
    ("(head (quote (1 2 3)))", Result.value(Expr.number(1))),
    ("(tail (quote (1 2 3)))", Result.value(Expr.list([Expr.number(2), Expr.number(3)]))),
    ("(cons 1 (quote (2 3)))", Result.value(Expr.list([
      Expr.number(1),
      Expr.number(2),
      Expr.number(3)
    ])
    )),
    ("(cons 1 (tail (quote (1 2 3)))", Result.value(Expr.list([
      Expr.number(1),
      Expr.number(2),
      Expr.number(3)
    ])
    )),
    ("(cond (false 2) (true 4))", Result.value(Expr.number(4))),
    ("(and true true true)", Result.value(Expr.bool(true))),
    ("(and true false true)", Result.value(Expr.bool(false))),
    ("(or true true true)", Result.value(Expr.bool(true))),
    ("(or true false true)", Result.value(Expr.bool(true))),
    ("(eq 2 2)", Result.value(Expr.bool(true))),
    ("(eq 2 3)", Result.value(Expr.bool(false))),
    ("""
     (def f (
     fn (a) (cond ((eq a 5) 1337
     ))))
     (f 5)
     """, Result.value(Expr.number(1337))),
    ("""
     (def f (
     fn (a) (
     cond
     ((eq a 0) (quote (1 3 3 7)))
     (true (f (- a 1)))
    )
    ))
    (f 3)
    """, Result.value(Expr.list([
      Expr.number(1),
      Expr.number(3),
      Expr.number(3),
      Expr.number(7)
    ])
    )),
    ("(def f (fn (a) (cond ((eq a 5) 1337) (true -1)))) (f 10)", Result.value(Expr.number(-1))),
    ("""
     (def apply (
     fn (f xs) (f xs)
     ))
     (apply (fn (a) (+ a 1)) 1)
     """, Result.value(Expr.number(2))),
    ("""
     (def fib (
     fn (x) (cond
     ((eq 0 x) 0)
     ((eq 1 x) 1)
     (true (+ (fib (- x 1)) (fib (- x 2))))
     )))
     (fib 11)
     """, Result.value(Expr.number(89))),
    ("""
     (def map (
     fn (f xs) (cond
     ((eq (head xs) null) (quote ()))
     (true (cons
     (f (head xs))
     (map f (tail xs))
     ))
     )))
     (map (fn (x) (+ x 1)) (quote (1 2 3)))
     """, Result.value(Expr.list([
       Expr.number(2),
       Expr.number(3),
       Expr.number(4)
     ]))),
     ("(quote (1 2 3))",
      Result.value(Expr.list([
        Expr.number(1),
        Expr.number(2),
        Expr.number(3)
      ]))),
      ("(quote (1 2 3))", Result.value(
        Expr.list([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3)
        ])
        )),
      ("(def def 2)", Result.error("\"def\" is already defined in the environment.")),
      ("(def a 1 2 3)", Result.error("\"def\" takes 2 arguments.")),
      (
        """
        (def filter
          (fn (pred xs)
          (cond
            ((eq xs (quote ())) (quote ()))
            ((pred (head xs)) (cons (head xs) (filter pred (tail xs))))
            (true (filter pred (tail xs)))
          )
          )
        )
        (filter (fn (x) (eq 2 x)) (quote (1 2 3 2 4 5 2)))
        """
       , Result.value(Expr.list([Expr.number(2), Expr.number(2), Expr.number(2)])))
  ]

  func testExample() {
    func green(_ str: String) -> String { return "\u{001B}[0;32m\(str)\u{001B}[0;37m" }
    func red(_ str: String) -> String { return "\u{001B}[0;31m\(str)\u{001B}[0;37m" }
    func pink(_ str: String) -> String { return "\u{001B}[0;35m\(str)\u{001B}[0;37m" }
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.

    SwiftLispTests.testProgramsAndValues.forEach { tup in
      let program = tup.0
      let expected = tup.1
      let lexOutput = lex(input: program)
      let exprs: [Expr] = read(input: lexOutput)
      let result: Result<Expr> = eval(exprs)
      XCTAssertTrue(expected == result)
      if expected == result {
        print("\(green("OK")): Expr \(pink(exprs.description)) gives \(pink("\(result)"))")
      } else {
        print("\(red("ERROR")): Expr \(pink(exprs.description))")
        print("       Result:   \(pink("\(result)"))")
        print("       Expected: \(pink("\(expected)"))")
      }
    }
  }

  static var allTests = [
    ("testExample", testExample)
  ]
}
