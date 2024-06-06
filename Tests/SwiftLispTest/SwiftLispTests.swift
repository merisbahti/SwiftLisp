import Testing

@testable import SwiftLispLib

@Test(
  "a bunch of programs",
  arguments: [
    ("(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))", .success(SwiftLispLib.Expr.number(186))),
    ("(+ 1 2)", .success(Expr.number(3))),
    (
      "(+ a 3)",
      makeEvalError("Variable not found: a\nContext is:\n============\n(+ a 3)\n   ^\n============")
    ),
    ("(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))", .success(SwiftLispLib.Expr.number(186))),
    ("(+ 1 2)", .success(Expr.number(3))),
    (
      "(+ a 3)",
      makeEvalError("Variable not found: a\nContext is:\n============\n(+ a 3)\n   ^\n============")
    ),
    ("(- 3 5)", .success(Expr.number(-2))),
    ("(1 2 3)", makeEvalError("1 is not a function (in pair (1 2 3))")),
    ("(def a (+ 5 3)) (def b 5) (+ a b)", .success(Expr.number(13))),
    ("(def f (fn (a b) (+ a a b))) (f 2 5)", .success(Expr.number(9))),
    ("((fn (a b) (+ a b)) 2 5)", .success(Expr.number(7))),
    ("(def negate (fn (a) (- a a a))) (negate 5)", .success(Expr.number(-5))),
    (
      "(def negate (fn (a) (- a a a))) (def add (fn (a b) (+ a b))) (add (negate 5) (negate 3))",
      .success(Expr.number(-8))
    ),
    ("(car '(1 2 3))", .success(Expr.number(1))),
    ("(cdr '(1 2 3))", .success(exprsToPairs([Expr.number(2), Expr.number(3)]))),
    (
      "(cons 1 '(2 3))",
      .success(
        exprsToPairs([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ])
      )
    ),
    (
      "(cons 1 (cdr '(1 2 3)))",
      .success(
        exprsToPairs([
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
       (define (f a) (
       cond
       ((eq a 0) '(1 3 3 7))
       (true (f (- a 1)))
      ))
      (f 3)
      """,
      .success(
        exprsToPairs([
          Expr.number(1),
          Expr.number(3),
          Expr.number(3),
          Expr.number(7),
        ])
      )
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
        exprsToPairs([
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
          ((eq xs null) '())
          (true (cons (f (car xs))
        (map f (cdr xs))
        ))
      )))
      (map (fn (x) (+ x 1)) '(1 2 3))
      """,
      .success(
        exprsToPairs([
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
          ((eq xs null) '())
          (true (cons (f (car xs))
        (map f (cdr xs))
        ))
      )))
      (map (fn (x) (+ x 1)) '())
      """,
      .success(
        exprsToPairs([]))
    ),
    (
      "'(1 2 3)",
      .success(
        exprsToPairs([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ]))
    ),
    (
      "'(1 2 3)",
      .success(
        exprsToPairs([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
        ])
      )
    ),
    ("(def def 2)", .success(.null)),
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
          ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
          (true (filter pred (cdr xs)))
        )
        )
      )
      (filter (fn (x) (eq 2 x)) '(1 2 3 2 4 5 2))
      """, .success(exprsToPairs([Expr.number(2), Expr.number(2), Expr.number(2)]))
    ),
    (
      """
      (def filter
        (fn (pred xs)
        (cond
          ((eq xs '()) '())
          ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
          (true (filter pred (cdr xs)))
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
    (
      """
      (let 
        (
          (a 1)
          (b 2)
        )
      )
      """,
      makeEvalError(
        "Expected two args to let, one list of bindings and one expr to evaluate, found: [((a 1) (b 2))]"
      )
    ),

    (
      """
      (let 
        (
          (a 1)
          (b 2)
        )
        (+ a b)
        (+ a b)
      )
      """,
      makeEvalError(
        "Expected two args to let, one list of bindings and one expr to evaluate, found: [((a 1) (b 2)), (+ a b), (+ a b)]"
      )
    ),
    (
      """
      (let 
        (
          (a 1)
          (b 2)
        )
        (+ a b)
      )
      """,
      .success(.number(3))
    ),

    (
      """
      (let ((a 10))
      (let 
        (
          (a 1)
          (b 2)
        )
        (+ a b)
      ))
      """,
      .success(.number(3))
    ),
    (
      """
      (define () (+ a b))
      """,
      makeEvalError(
        "define's first arg should be a symbol or list of symbols (at least 1 symbols), found: null"
      )
    ),

    (
      """
      (define )
      """,
      makeEvalError(
        "define takes two args")
    ),
    (
      """
      (define (f a b) (+ a b))
      (f 1 2)
      """, .success(.number(3))
    ),
    (
      """
      (define (odd? x) (eq (% x 2) 1))
      (odd? 3)
      """, .success(.bool(true))
    ),

    (
      """
      (define (odd? x) (eq (% x 2) 1))
      (odd? 6)
      """, .success(.bool(false))
    ),
    (
      """
      (define (even? x) (eq (% x 2) 0))
      (even? 3)
      """, .success(.bool(false))
    ),
    (
      """
      (define (even? x) (eq (% x 2) 0))
      (even? 6)
      """, .success(.bool(true))
    ),
    (
      """
      (def filter
        (fn (pred xs)
          (cond
            ((eq xs '()) '())
            ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
            (true (filter pred (cdr xs))))))
      (define (odd? x) (eq (% x 2) 1))
      (define (even? x) (eq (% x 2) 0))
      (define
        (same-parity parity . xs)
        (let
          (
            (parityFn (cond
                       ((odd? parity) odd?)
                       (else even?))))
          (cons parity (filter parityFn xs))))
      (same-parity 1 2 3 4 5 6 7)
      """, .success(exprsToPairs([.number(1), .number(3), .number(5), .number(7)]))
    ),
    (
      """
      (def filter
        (fn (pred xs)
          (cond
            ((eq xs '()) '())
            ((pred (car xs)) (cons (car xs) (filter pred (cdr xs))))
            (true (filter pred (cdr xs))))))
      (define (odd? x) (eq (% x 2) 1))
      (define (even? x) (eq (% x 2) 0))
      (define
        (same-parity parity . xs)
        (let
          (
            (parityFn (cond
                       ((odd? parity) odd?)
                       (else even?))))
          (cons parity (filter parityFn xs))))
      (same-parity 2 3 4 5 6 7)
      """, .success(exprsToPairs([.number(2), .number(4), .number(6)]))
    ),
    (
      """

        (list
          (number? false)
          (number? '(1 2 3))
          (pair? '(1 2 3))
          (pair? '())
          (number? 1)
          (number? (+ 1 2))
          (bool? false)
          (bool? true))
              
      """,
      .success(
        exprsToPairs(
          [
            .bool(false), .bool(false), .bool(true),
            .bool(true), .bool(true), .bool(true),
            .bool(true), .bool(true),
          ]))
    ),
    (
      """
        (define a 1)
        (define (f x) 
          (define a 2) 
          (+ a x))
        (list a (f 3) a)
      """, .success(exprsToPairs([.number(1), .number(5), .number(1)]))
    ),
    (
      """
      ;; one comment
        (list ;; some comment
          (number? false)
          (number? '(1 2 3)) ;; funny comment


        ;; two comments
        ;; other comment


        ;; comment after a while


          
          (pair? '(1 2 3))
          (pair? '())
          (number? 1)
          (number? (+ 1 2))
          (bool? false)
          (bool? true))
          ;; ending comment
              
      """,
      .success(
        exprsToPairs(
          [
            .bool(false), .bool(false), .bool(true),
            .bool(true), .bool(true), .bool(true),
            .bool(true), .bool(true),
          ]))
    ),
    (
      """
      (define (lower-fn op) (op 1 1))
      (define (top-fn op)
        (lower-fn (fn (x y) (op 1))))
      (top-fn (fn (x) x))
      """, .success(.number(1))
    ),
    (
      """
      (define (lower-fn op) something-else)
      (define (top-fn op)
        (lower-fn (fn (x y)
                   (op 1))))
      (define something-else 10)
      (top-fn (fn (x) 1))      
      """, .success(.number(10))
    ),
    (
      """
      (eval (list + 1 2 3))      
      """, .success(.number(6))
    ),
    (
      """
      (or false false true)      
      """, .success(.bool(true))
    ),
    (
      """
      (define (lower-fn op) something-else)
      (define (top-fn op something-else)
        (lower-fn (fn (x y)
                   (op 1))))
      (top-fn (fn (x) 1) 10)      
      """,
      makeEvalError(
        "Variable not found: something-else\nContext is:\n============\n(define (lower-fn op) something-else)\n                      ^^^^^^^^^^^^^^\n(define (top-fn op something-else)\n============"
      )
    ),
    (
      """
        (define (append list1 list2)
          (cond 
            ((eq list1 '()) list2)
            (else (cons (car list1) (append (cdr list1) list2)))))
        (append (list 1 2 3) (list 4 5 6))
      """,
      .success(
        exprsToPairs([
          Expr.number(1),
          Expr.number(2),
          Expr.number(3),
          Expr.number(4),
          Expr.number(5),
          Expr.number(6),
        ]))
    ),
  ]
)
func someTest(_ tuple: (String, Result<SwiftLispLib.Expr, EvalError>)) {

  let (program, expectedResult) = tuple

  let exprs: Result<[Expr], EvalError> = SwiftLispLib.read(input: program)
  let result: Result<Expr, EvalError> = exprs.flatMap { eval($0) }
  #expect(result == expectedResult)
}

@Test(
  "to string",
  arguments: [
    (Expr.pair((.number(0), .number(0))), "(0 . 0)"),
    (
      .pair((.pair((.pair((.pair((.null, .number(4))), .number(3))), .number(2))), .number(1))),
      "((((null . 4) . 3) . 2) . 1)"
    ),
    (Expr.pair((.number(0), Expr.pair((.number(1), Expr.pair((.number(1), .null)))))), "(0 1 1)"),
    (Expr.pair((.number(0), Expr.pair((.number(1), .number(0))))), "(0 1 . 0)"),
    (Expr.pair((.number(0), Expr.pair((.number(1), .null)))), "(0 1)"),
  ]
)
func someTest(_ tuple: (Expr, String)) {
  let (expr, expectedResult) = tuple
  #expect("\(expr)" == expectedResult)
}
