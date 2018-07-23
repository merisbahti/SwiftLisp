let testPrograms = [
  "(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))",
  "(+ 1 2)",
  "(+ a 3)",
  "(- 3 5)",
  "(1 2 3)",
  "(def a (+ 5 3)) (def b 5) (+ a b)",
  "(def f (fn (a b) (+ a a b))) (f 2 5)",
  "((fn (a b) (+ a b)) 2 5)",
  "(def negate (fn (a) (- a a a))) (negate 5)",
  "(def negate (fn (a) (- a a a))) (def add (fn (a b) (+ a b))) (add (negate 5) (negate 3))"
]
let results = [
  Result.value(Expr.number(186)),
  Result.value(Expr.number(3)),
  Result.error("Variable not found: a"),
  Result.value(Expr.number(-2)),
  Result.error("Head of list is not a function, 1 in list (1 2 3)"),
  Result.value(Expr.number(13)),
  Result.value(Expr.number(9)),
  Result.value(Expr.number(7)),
  Result.value(Expr.number(-5)),
  Result.value(Expr.number(-8))
]

func green(_ str: String) -> String {
  return "\u{001B}[0;32m\(str)\u{001B}[0;37m"
}
func red(_ str: String) -> String {
  return "\u{001B}[0;31m\(str)\u{001B}[0;37m"
}
func pink(_ str: String) -> String {
  return "\u{001B}[0;35m\(str)\u{001B}[0;37m"
}

zip(testPrograms, results).forEach { tup in
  let program = tup.0
  let expected = tup.1
  let lexOutput = lex(input: program)
  let exprs: [Expr] = read(input: lexOutput)
  let result: Result<Expr> = eval(exprs)
  if expected == result {
    print("\(green("OK")): Expr \(pink(exprs.description)) gives \(pink("\(result)"))")
  } else {
    print("\(red("ERROR")): Expr \(pink(exprs.description)) gives \(pink("\(result)"))")
    print("       Expected: \(pink("\(expected)"))")
  }

}
