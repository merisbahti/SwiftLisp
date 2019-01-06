@testable import SwiftLispLib
import Foundation
let arguments = CommandLine.arguments
if (arguments.count == 2) {
  let filePath = arguments[1]
  let fileContent = try? String(contentsOfFile: filePath)
  if let input = fileContent {
    let exprs: Result<[Expr]> = read(input: input)
    let result: Result<Expr> = exprs.flatMap { eval($0) }
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
