func runPrint(input: String) {
  let lexOutput = lex(input: input)
  let exprs = read(input: lexOutput)
  print(input)
  print(eval(exprs))
}
[
"(+ 12 34 (+ 56 78 (+ 1 2)) (+ 1 2))",
"(+ 1 2)",
"(+ a 3)",
"(- 3 5)",
"(1 2 3)",
"(def a (+ 5 3)) (def b 5) (+ a b)",
"(def f (fn (a b) (+ a a b))) (f 2 5)",
"((fn (a b) (+ a b)) 2 5)",
"(fn (a b) (+ a b))",
"(def f (fn (a b) (+ a (f a b)))) (f 2 5)"
].forEach { input in
  runPrint(input: input)
}
