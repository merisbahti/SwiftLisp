func runPrint(input: String) {
  let exprs = read(input: lex(input: input))
  print(exprs)
  exprs.forEach { print(eval(expr: $0, env: stdLib)) }
}
[
"(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2)) ",
"(+ 1 2)",
"(+ a 3)",
"(- 3 5)",
"(1 2 3)",
"(def a 3))",
"(def a (lambda (a b) (+ a b))"
].forEach { input in
  print(input)
  runPrint(input: input)
}
