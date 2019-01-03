@testable import SwiftLispLib
import Foundation
var input: String = ""
while let line = readLine() { input += line }
let lexOutput = lex(input: input)
let exprs: [Expr] = read(input: lexOutput)
let result: Result<Expr> = eval(exprs)
switch result {
  case .error(let e):
    print(e)
    exit(1)
  default:
    exit(0)
}
