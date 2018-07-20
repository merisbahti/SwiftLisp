print(read(input: lex(input: "(+ 12 34 (+ 56 78))")))
print(read(input: lex(input: "+")))
print(eval(
  expr: .list(
    [.variable("+"), .number(5), .number(5)]
    )))
