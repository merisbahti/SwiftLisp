import Foundation

@testable import SwiftLispLib

let arguments = CommandLine.arguments
if arguments.count == 2 {
  let filePath = arguments[1]
  let fileContent = try? String(contentsOfFile: filePath)
  if let input = fileContent {
    let exprs: Result<[Expr], EvalError> = read(input: input)
    let result: Result<Expr, EvalError> = exprs.flatMap { eval($0) }
    switch result {
    case .failure(let e):
      print(e)
      exit(1)
    case .success(let e):
      print(e)
      exit(0)
    }
  } else {
    print("Cannot find file: \(filePath)")
    exit(1)
  }
} else {
  print("1 argument, file path pls")
}
