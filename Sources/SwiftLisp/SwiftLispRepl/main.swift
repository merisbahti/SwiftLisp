import Foundation

import SwiftLispLib

let preludePath = "./prelude.scm"

let arguments = CommandLine.arguments
if arguments.count == 2 {
  let filePath = arguments[1]
  let fileContent = try? String(contentsOfFile: filePath)

  let preludeContent = try? String(contentsOfFile: preludePath)

  guard case .some(let preludeContent) = preludeContent else {
    print("Could not find prelude at \(preludePath)")
    exit(1)
  }

  guard case .some(let input) = fileContent else {
    print("1 argument, file path pls")
    exit(1)
  }

  let env = Env(
    [:], baseEnv: stdLib
  )

  let preludeResult = read(input: preludeContent).flatMap { evalWithEnv($0, env) }

  guard case .success(_) = preludeResult else {
    switch preludeResult {
    case .failure(let evalError):
      print("Failed to evaluate preludeResult: \(evalError.message)")
    case _: print("weird error: \(preludeResult)")
    }
    exit(1)
  }

  let exprs: Result<[Expr], EvalError> = read(input: input)
  let result: Result<Expr, EvalError> = exprs.flatMap { evalWithEnv($0, env) }
  switch result {
  case .failure(let e):
    print(e.message)
    exit(1)
  case .success(let e):
    print(e)
    exit(0)
  }

}
