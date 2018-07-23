enum Expr {
  case number(Int)
  case list([Expr])
  case variable(String)
  case fun(([Expr], Env) -> EvalResult)
  case null
}
extension Expr: Equatable {
  static func == (lhs: Expr, rhs: Expr) -> Bool {
    switch (lhs, rhs) {
    case (.number(let nr1), .number(let nr2)):
      return nr1 == nr2
    default:
      return false
    }
  }
}
typealias EvalResult = Result<(Expr, Env)>
typealias Env = [String: Expr]

let getSymbolsFromListExpr: (Expr) -> Result<[String]> = { exprs in
  switch exprs {
  case Expr.list(let list):
    return list.reduce(Result<[String]>.value([])) { acc, expr in
      return acc.flatMap { resultAcc in
        switch expr {
        case Expr.variable(let str):
          return .value(resultAcc + [str])
        default:
          return Result<[String]>.error("All members in expr must be symbol.")
        }
      }
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
    return unapply(tokenList)
    .flapFlap("Cannot evaluate empty list: \(tokenList)")
    .flatMap { (headTail: (Expr, [Expr])) in
      let head = headTail.0
      let tail = headTail.1
      return eval(head, env).flatMap { headExpr, env in
        switch headExpr {
        case .fun(let fun):
          return fun(tail, env)
        case _:
          return .error("Head of list is not a function, \(head) in list \(expr)")
        }
      }
    }
  case .number(let int):
    return .value((.number(int), env))
  case .variable(let val):
    if let expr = env[val] {
      return eval(expr, env)
    } else {
      return .error("Variable not found: \(val)")
    }
  case .fun:
    return .value((expr, env))
  case .null:
    return .error("Can't eval null")
  }
}
func eval(_ exprs: [Expr]) -> Result<Expr> {
  return unapply(exprs).flatMap { (head, tail) in
    return tail.reduce(
      eval(head, stdLib), { res, expr in
        return res.flatMap { _, newEnv in return eval(expr, newEnv) }
      })
  }.flatMap { return .value($0.0)}
}
