let stdLib: Env = [
"+": Expr.fun({ (exprs: [Expr], env: Env) in
  unapply(exprs).flatMap { head, tail in
    return tail.reduce(eval(head, env)) { accRes, expr in
      return operate(res1: accRes, res2: eval(expr, env), opfun: { expr1, expr2 in
        switch (expr1, expr2) {
        case (Expr.number(let num1), Expr.number(let num2)):
          return EvalResult.value((Expr.number(num1 + num2), env))
        case _:
          return EvalResult.error("No number in + operand")
        }
                     })
    }
  }
              }),
"-": Expr.fun({ (exprs: [Expr], env: Env) in
  unapply(exprs).flatMap { head, tail in
    return tail.reduce(eval(head, env)) { accRes, expr in
      return operate(res1: accRes, res2: eval(expr, env), opfun: { expr1, expr2 in
        switch (expr1, expr2) {
        case (Expr.number(let num1), Expr.number(let num2)):
          return EvalResult.value((Expr.number(num1 - num2), env))
        case _:
          return EvalResult.error("No number in - operand")
        }
                     })
    }
  }
              }),
"def": Expr.fun({ (exprs: [Expr], env: Env) in
  let head = exprs.first
  let expr = exprs.dropFirst().first
  if let symbol = head {
    switch symbol {
    case Expr.variable(let variableName):
      return eval(expr!, env).flatMap { newExpr, newEnv in
        return .value(
          (
            Expr.null,
          env.merging([variableName: newExpr]) { newEnv, _ in newEnv })
          )
      }
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
  return getSymbolsFromListExpr(head!).flatMap { symbols in
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
        let bodyApplyResult = eval(Expr.list(bodyList), applicationEnv)
        return bodyApplyResult.flatMap { result in
          Result.value((result.0, fnEnv))
        }
      }), env))
    case let other:
      return .error("Second argument to fn should be a list, got: \(other)")
    }
  }
})
]
