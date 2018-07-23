func intIntOperator(_ opr: @escaping (Int, Int) -> Int, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    return unapply(exprs).flatMap { headTail in
      let head = headTail.0
      let tail = headTail.1
      return tail.reduce(eval(head, env)) { accRes, expr in
        return accRes.flatMap { lhsEval in
          return eval(expr, env).flatMap { rhsEval in
            switch (lhsEval, rhsEval) {
            case ((Expr.number(let nr1), _), (Expr.number(let nr2), _)):
              return Result.value((Expr.number(opr(nr1, nr2)), env))
            default:
              return EvalResult.error("No number in \(symbol) operand, lhsEval \(lhsEval) rhsEval: \(rhsEval)")
            }
          }}
      }
    }
  })
}
func boolBoolOperator(_ opr: @escaping (Bool, Bool) -> Bool, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    return unapply(exprs).flatMap { headTail in
      let head = headTail.0
      let tail = headTail.1
      return tail.reduce(eval(head, env)) { accRes, expr in
        return accRes.flatMap { lhsEval in
          return eval(expr, env).flatMap { rhsEval in
            switch (lhsEval, rhsEval) {
            case ((Expr.bool(let nr1), _), (Expr.bool(let nr2), _)):
              return Result.value((Expr.bool(opr(nr1, nr2)), env))
            default:
              return EvalResult.error("No bool in \(symbol) operand, lhsEval \(lhsEval) rhsEval: \(rhsEval)")
            }
          }}
      }
    }
  })
}
func comparisonOperator(_ opr: @escaping (Expr, Expr) -> Bool, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    return unapply(exprs).flatMap { headTail in
      let head = headTail.0
      let tail = headTail.1
      return tail.reduce(eval(head, env)) { accRes, expr in
        return accRes.flatMap { lhsEval in
          return eval(expr, env).flatMap { rhsEval in
            switch (lhsEval, rhsEval) {
            case ((let expr1, _), (let expr2, _)):
              return Result.value((Expr.bool(opr(expr1, expr2)), env))
            default:
              return EvalResult.error("No bool in \(symbol) operand, lhsEval \(lhsEval) rhsEval: \(rhsEval)")
            }
          }}
      }
    }
  })
}
let stdLib: Env = [
"+": intIntOperator({$0 + $1}, "+"),
"-": intIntOperator({$0 - $1}, "-"),
"*": intIntOperator({$0 * $1}, "*"),
"/": intIntOperator({$0 / $1}, "/"),
"and": boolBoolOperator({$0 && $1}, "and"),
"or": boolBoolOperator({$0 || $1}, "or"),
"eq": comparisonOperator({$0 == $1}, "eq"),
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
"true": Expr.bool(true),
"false": Expr.bool(false),
"cond": Expr.fun({ (exprs: [Expr], env: Env) in
  return (
    exprs.reduce(
      Result.value(Expr.null), { (acc: Result<Expr>, condExpr: Expr) in
        return acc.flatMap { (accExpr: Expr) in
          switch accExpr {
          case Expr.null:
            switch condExpr {
            case Expr.list(let condExprList):
              if let predExpr = condExprList.first, let thenExpr = condExprList.dropFirst().first {
                return eval(predExpr, env).flatMap { (evaledPredExpr, _) in
                  switch evaledPredExpr {
                  case Expr.bool(true):
                    return eval(thenExpr, env).flatMap {
                      let result = Result<Expr>.value($0.0)
                      return result
                    }
                  default:
                    return .value(Expr.null)
                  }
                }
              } else {
                return .error("Each argument to cond should be pair of (predExpr thenExpr), got: \(condExpr)")
              }
            default:
              return .error("Each argument to cond should be pair of (predExpr thenExpr), got: \(condExpr)")
            }
            // continue
          case let value:
            return .value(value)
          }
        }
      })
    ).flatMap {
      return .value(($0, env))
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
          uniquingKeysWith: { argsEnv, fnEnv in argsEnv}
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
