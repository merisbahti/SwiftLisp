@testable import SwiftLispLib
import Foundation
doThing()
let arguments = CommandLine.arguments
if (arguments.count == 2) {
  let filePath = arguments[1]
  let fileContent = try? String(contentsOfFile: filePath)
  if let input = fileContent {
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
  } else {
    print("Cannot find file: \(filePath)")
    exit(1)
  }
} else {
  print("1 argument, file path pls")
}
