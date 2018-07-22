enum Result<T> {
  case value(T)
  case error(String)
}
enum Expr {
  case number(Int)
  case list([Expr])
  case variable(String)
  case fun(([Expr], Env) -> EvalResult)
}
typealias EvalResult = Result<(Expr, Env)>
func operate(res1: EvalResult, res2: EvalResult, opfun: (Expr, Expr) -> EvalResult) -> EvalResult {
  return map(
    res1, { expr1 in
      map(
        res2, { expr2 in
          return opfun(expr1.0, expr2.0)
        }
        )
    })
}
func map<A, B>(_ res: Result<A>, _ fun: (A) -> Result<B>) -> Result<B> {
  switch res {
  case .value(let val):
    return fun(val)
  case .error(let err):
    return Result<B>.error(err)
  }
}

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

let stdLib: Env = [
"+": Expr.fun({ (exprs: [Expr], env: Env) in
  return exprs.reduce(EvalResult.value((Expr.number(0), env)), { acc, expr in
    return operate(res1: acc, res2: eval(expr: expr, env: env), opfun: { expr1, expr2 in
      switch (expr1, expr2) {
      case (Expr.number(let num1), Expr.number(let num2)):
        return EvalResult.value((Expr.number(num1 + num2), env))
      case _:
        return EvalResult.error("No number in + operand")
      }
                   })
  })
}),
"def": Expr.fun({ (exprs: [Expr], env: Env) in
  let head = exprs.first
  let expr = exprs.dropFirst().first
  if let symbol = head {
    switch symbol {
    case Expr.variable(let variableName):
      return map(eval(expr: expr!, env: env), { newExpr, newEnv in
        return .value(
          (
          newExpr,
          env.merging([variableName: newExpr]) { newEnv, _ in newEnv })
          )
      })
    case _:
      return .error("First argument to def must be symbol, found: \(symbol)")
    }
  }
  return .error("No symbol as first argument to def.")
                }),
"fn": Expr.fun({ (exprs: [Expr], env: Env) in
  let head = exprs.first
  let body = exprs.dropFirst().first
  if head == nil {
    return .error("Missing first arg to fn, list of symbols")
  }
  if body == nil {
    return .error("Second arg to fn undefined, should be list.")
  }
  return map(getSymbolsFromListExpr(head!), { symbols in
    switch body! {
    case Expr.list(let bodyList):
      return Result.value((Expr.fun({ (fnArgs, fnEnv) in
        if fnArgs.capacity != symbols.capacity {
          return .error("Wrong nr of args to fn, \(fnArgs) \(symbols)")
        }
        let emptyEnv: Env = [:]
        let argsEnv: Env = zip(symbols, fnArgs).reduce(
        emptyEnv, { (acc: Env, kvs: (String, Expr)) in
          acc.merging([kvs.0: kvs.1], uniquingKeysWith: { _, kvs in kvs })
        })
        let applicationEnv: Env = argsEnv.merging(
          fnEnv,
          uniquingKeysWith: { argsEnv, _ in argsEnv}
        )
        let bodyApplyResult = eval(expr: Expr.list(bodyList), env: applicationEnv)
        return map(bodyApplyResult, { result in
                     Result.value((result.0, fnEnv))
                     })
                                    }), env))
    case let other:
      return .error("Second argument to fn should be a list, got: \(other)")
    }
             })
})
]
func eval(expr: Expr, env: Env) -> EvalResult {
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
      return map(eval(expr: head, env: env), mapFunc)
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
  }
}
func eval(exprs: [Expr]) -> EvalResult {
  if let head = exprs.first {
    return exprs.reduce(
      eval(expr: head, env: stdLib), { res, expr in
        return map(res, { _, newEnv in return eval(expr: expr, env: newEnv) })
      }
    )
  } else {
    return .error("Empty expression?")
  }
}
