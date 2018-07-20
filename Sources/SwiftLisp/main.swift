func runPrint(input: String) {
  let lexOutput = lex(input: input)
  let exprs = read(input: lexOutput)
  print(eval(exprs: exprs))
}
[
"(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))",
"(+ 1 2)",
"(+ a 3)",
"(- 3 5)",
"(1 2 3)",
"(def a (+ 5 3)) (def b 5) (+ a b)",
"(def a (lambda (a b) (+ a b))"
].forEach { input in
  runPrint(input: input)
}
