import Testing

@testable import SwiftLispLib

@Test(
  "a bunch of programs",
  arguments: [
    ("(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))", .success(SwiftLispLib.Expr.number(186))),
    ("(+ 1 2)", .success(Expr.number(3))),
    ("(+ a 3)", makeEvalError("Variable not found: a")),
    ("(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))", .success(SwiftLispLib.Expr.number(186))),
    ("(+ 1 2)", .success(Expr.number(3))),
    ("(+ a 3)", makeEvalError("Variable not found: a")),
    ("(- 3 5)", .success(Expr.number(-2))),
    ("(1 2 3)", makeEvalError("Head of list is not a function, 1 in list (1 2 3)")),
    ("(def a (+ 5 3)) (def b 5) (+ a b)", .success(Expr.number(13))),
    ("(def f (fn (a b) (+ a a b))) (f 2 5)", .success(Expr.number(9))),
    ("((fn (a b) (+ a b)) 2 5)", .success(Expr.number(7))),
    ("(def negate (fn (a) (- a a a))) (negate 5)", .success(Expr.number(-5))),
    (
      "(def negate (fn (a) (- a a a))) (def add (fn (a b) (+ a b))) (add (negate 5) (negate 3))",
      .success(Expr.number(-8))
    ),
    ("(head '(1 2 3))", .success(Expr.number(1))),
    ("(tail '(1 2 3))", .success(Expr.list([Expr.number(2), Expr.number(3)]))),
    (
      "(cons 1 '(2 3))",
      .success(
        Expr.list([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ])
      )
    ),
    (
      "(cons 1 (tail '(1 2 3)))",
      .success(
        Expr.list([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ])
      )
    ),
    ("(cond (false 2) (true 4))", .success(Expr.number(4))),
    ("(and true true true)", .success(Expr.bool(true))),
    ("(and true false true)", .success(Expr.bool(false))),
    ("(or true true true)", .success(Expr.bool(true))),
    ("(or true false true)", .success(Expr.bool(true))),
    ("(eq 2 2)", .success(Expr.bool(true))),
    ("(eq 2 3)", .success(Expr.bool(false))),
    (
      """
      (def f (fn (a) (cond ((eq a 5) 1337))))
      (f 5)
      """, .success(Expr.number(1337))
    ),
    (
      """
       (def f (
       fn (a) (
       cond
       ((eq a 0) '(1 3 3 7))
       (true (f (- a 1)))
      )
      ))
      (f 3)
      """,
      .success(
        Expr.list([
          Expr.number(1),
          Expr.number(3),
          Expr.number(3),
          Expr.number(7),
        ])
      )
    ),
    ("(def f (fn (a) (cond ((eq a 5) 1337) (true -1)))) (f 10)", .success(Expr.number(-1))),
    (
      """
      (def apply (
      fn (f xs) (f xs)
      ))
      (apply (fn (a) (+ a 1)) 1)
      """, .success(Expr.number(2))
    ),
    (
      """
      (def fib (
      fn (x) (cond
      ((eq 0 x) 0)
      ((eq 1 x) 1)
      (true (+ (fib (- x 1)) (fib (- x 2))))
      )))
      (fib 11)
      """, .success(Expr.number(89))
    ),
    (
      """
      (def map (
        fn (f xs) 
        (cond
          ((eq (head xs) null) '())
          (true (cons (f (head xs))
        (map f (tail xs))
        ))
      )))
      (map (fn (x) (+ x 1)) '(1 2 3))
      """,
      .success(
        Expr.list([
          Expr.number(2),
          Expr.number(3),
          Expr.number(4),
        ]))
    ),

    (
      """
      (def map (
        fn (f xs) 
        (cond
          ((eq (head xs) null) '())
          (true (cons (f (head xs))
        (map f (tail xs))
        ))
      )))
      (map (fn (x) (+ x 1)) '())
      """,
      .success(
        Expr.list([]))
    ),
    (
      "'(1 2 3)",
      .success(
        Expr.list([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ]))
    ),
    (
      "'(1 2 3)",
      .success(
        Expr.list([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ])
      )
    ),
    ("(def def 2)", makeEvalError("\"def\" is already defined in the environment.")),
    ("(def a 1 2 3)", makeEvalError("\"def\" takes 2 arguments.")),
    (
      """
      (def f
        (fn (n)
          (cond
            ((< n 3) 3)
            (true (+
              (* 1 (f (- n 1)))
              (* 2 (f (- n 2)))
              (* 3 (f (- n 3)))
            ))
        ))
      )
      (f 5)
      """,
      .success(.number(78))
    ),
    (
      """
      (def filter
        (fn (pred xs)
        (cond
          ((eq xs '()) '())
          ((pred (head xs)) (cons (head xs) (filter pred (tail xs))))
          (true (filter pred (tail xs)))
        )
        )
      )
      (filter (fn (x) (eq 2 x)) '(1 2 3 2 4 5 2))
      """, .success(Expr.list([Expr.number(2), Expr.number(2), Expr.number(2)]))
    ),
    (
      """
      (def filter
        (fn (pred xs)
        (cond
          ((eq xs '()) '())
          ((pred (head xs)) (cons (head xs) (filter pred (tail xs))))
          (true (filter pred (tail xs)))
        )
        )
      )
      (filter (fn (x) (eq 2 x)) '(1 2 3 2 4 5 2) '(1))
      """, makeEvalError("Wrong nr of args to fn, got \(3) needed \(2)")
    ),
    (
      """
      (str-append "hello" "" " " "" "world")
      """, .success(.string("hello world"))
    ),
  ]
)
func someTest(_ tuple: (String, Result<SwiftLispLib.Expr, EvalError>)) {

  let (program, expectedResult) = tuple

  let exprs: Result<[Expr], EvalError> = SwiftLispLib.read(input: program)
  let result: Result<Expr, EvalError> = exprs.flatMap { eval($0) }
  #expect(result == expectedResult)
}
