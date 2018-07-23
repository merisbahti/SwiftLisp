let stdLib: Env = [
"+": Expr.fun({ (exprs: [Expr], env: Env) in
  unapply(exprs).flatMap { headTail in
    let head = headTail.0
    let tail = headTail.1
    return tail.reduce(eval(head, env)) { accRes, expr in
      return accRes.flatMap { lhsEval in
        return eval(expr, env).flatMap { rhsEval in
          switch (lhsEval, rhsEval) {
          case ((Expr.number(let nr1), _), (Expr.number(let nr2), _)):
            return Result.value((Expr.number(nr1 + nr2), env))
          default:
            return EvalResult.error("No number in + operand, lhsEval \(lhsEval) rhsEval: \(rhsEval)")
          }
        }}
    }
  }
              }),
"-": Expr.fun({ (exprs: [Expr], env: Env) in
  unapply(exprs).flatMap { headTail in
    let head = headTail.0
    let tail = headTail.1
    return tail.reduce(eval(head, env)) { accRes, expr in
      return accRes.flatMap { lhsEval in
        return eval(expr, env).flatMap { rhsEval in
          switch (lhsEval, rhsEval) {
          case ((Expr.number(let nr1), _), (Expr.number(let nr2), _)):
            return Result.value((Expr.number(nr1 - nr2), env))
          default:
            return EvalResult.error("No number in - operand")
          }
        }}
    }
  }
              }),
"head": Expr.fun({ (exprs: [Expr], env: Env) in
  if let firstArg = exprs.first {
    switch firstArg {
    case .list(let list):
      if let head = list.first {
        return .value((head, env))
      } else {
        return .error("Cannot apply head to empty list")
      }
    default:
      return .error("Can only apply head to list, got: \(firstArg)")
    }
  } else {
    return .error("head takes 1 argument, a list.")
  }
                 }),
"tail": Expr.fun({ (exprs: [Expr], env: Env) in
  if let firstArg = exprs.first {
    switch firstArg {
    case .list(let list):
      return .value((Expr.list(Array(list.dropFirst())), env))
    default:
      return .error("Can only apply head to list, got: \(firstArg)")
    }
  } else {
    return .error("tail takes 1 argument, a list.")
  }
                 }),
"cons": Expr.fun({ (exprs: [Expr], env: Env) in
  if let firstArg = exprs.first, let secondArg = exprs.dropFirst().first {
    switch secondArg {
    case .list(let list):
      return .value((Expr.list([firstArg] + list), env))
    default:
      return .error("Second arg to cons must be list, got \(firstArg)")
    }
  } else {
    return .error("takes 2 arguments, an element and a list.")
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
        // Evaluate all fnArgs
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
