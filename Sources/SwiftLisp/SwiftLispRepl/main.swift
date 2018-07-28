@testable import SwiftLispLib
let lexOutput = lex(input: "(print (and 1 2)")
let exprs: [Expr] = read(input: lexOutput)
let result: Result<Expr> = eval(exprs)
print(result)
