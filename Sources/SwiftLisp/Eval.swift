enum Expr {
  case number(Int)
  case list([Expr])
  case variable(String)
  case fun(([Expr], Env) -> EvalResult)
  case null
}
typealias EvalResult = Result<(Expr, Env)>
typealias Env = [String: Expr]

let getSymbolsFromListExpr: (Expr) -> Result<[String]> = { exprs in
  switch exprs {
  case Expr.list(let list):
    return list.reduce(Result<[String]>.value([])) { acc, expr in
      return map(
        acc, { resultAcc in
          switch expr {
          case Expr.variable(let str):
            return .value(resultAcc + [str])
          default:
            return Result<[String]>.error("All members in expr must be symbol.")
          }
        }
      )
    }
  case let other:
    return Result<[String]>.error("Expected list, got: \(other)")
  }
}
func unapply<T>(_ list: [T]) -> Result<(T, [T])> {
  let head = list.first
  let tail = list.dropFirst()
  if let head = head {
    return Result<(T, [T])>.value((head, Array(tail)))
  } else {
    return Result<(T, [T])>.error("Failure to unpack list.")
  }
}

func eval(_ expr: Expr, _ env: Env) -> EvalResult {
  switch expr {
  case .list(let tokenList):
    let tail = Array(tokenList.dropFirst())
    if let head = tokenList.first {
      let mapFunc: (Expr, Env) -> EvalResult = { expr, env in
        switch expr {
        case .fun(let fun):
          return fun(tail, env)
        case let other:
          return .error("Head of list is not a function, \(head) in list \(expr) type: \(other)")
        }
      }
      return map(eval(head, env), mapFunc)
    } else {
      return .error("Cannot evaluate empty list")
    }
  case .number(let int):
    return .value((.number(int), env))
  case .variable(let val):
    if let expr = env[val] {
      return .value((expr, env))
    } else {
      return .error("Variable not found: \(val), env: \(env)")
    }
  case .fun:
    return .error("Cannot eval function. Maybe return self here?")
  case .null:
    return .error("Can't eval null")
  }
}
func eval(_ exprs: [Expr]) -> EvalResult {
  return map(unapply(exprs)) { (head, tail) in
    return tail.reduce(
      eval(head, stdLib), { res, expr in
        return map(res, { _, newEnv in return eval(expr, newEnv) })
      })
  }
}
