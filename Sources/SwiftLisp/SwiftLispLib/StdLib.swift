func intIntOperator(_ opr: @escaping (Int, Int) -> Int, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }

    let exprsVerified: Result<[Int], EvalError> = exprsEvaled.reduce(.success([])) { acc, curr in
      switch (acc, curr) {
      case (.failure(let evalError), _): return .failure(evalError)
      case (.success(let acc), .success((.number(let nr), _))):
        return .success(acc.appending(nr))
      case (_, .success(let expr)):
        return makeEvalError("Error evaling \(symbol), expected numbers but found: \(expr)")
      case (_, .failure(let evalFailure)):
        return .failure(evalFailure)
      }
    }

    guard case let .success(ints) = exprsVerified else {
      return exprsVerified.map { _ in (.number(0), env) }
    }

    let a = unapply(ints).map { (head, tail) in
      Expr.number(tail.reduce(head) { (acc, curr) in opr(acc, curr) })
    }

    return a.map { b in (b, env) }

  })
}
func stringStringOperator(_ opr: @escaping (String, String) -> String, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    return unapply(exprs).flatMap { (head, tail) in
      return tail.reduce(eval(head, env)) { accRes, expr in
        return accRes.flatMap { lhsEval in
          return eval(expr, env).flatMap { rhsEval in
            switch (lhsEval, rhsEval) {
            case ((Expr.string(let nr1), _), (Expr.string(let nr2), _)):
              return Result.success((Expr.string(opr(nr1, nr2)), env))
            default:
              return makeEvalError(
                "No number in \(symbol) operand, lhsEval \(lhsEval) rhsEval: \(rhsEval)"
              )
            }
          }
        }
      }
    }
  })
}
func comparisonOperator(_ symbol: String, _ opr: @escaping (Expr, Expr) -> Bool) -> Expr {
  return Expr.fun { (exprs: [Expr], env: Env) -> EvalResult in
    if let firstArg = exprs.first, let secondArg = exprs.dropFirst().first {
      return eval(firstArg, env).map { firstRes in
        firstRes.0
      }.flatMap { firstRes in
        eval(secondArg, env).map { secondRes in (firstRes, secondRes.0) }
      }.flatMap { args in
        .success((.bool(opr(args.0, args.1)), env))
      }
    } else {
      return makeEvalError("\(symbol) takes 2 arguments.")
    }
  }
}

func boolBoolOperator(_ opr: @escaping (Bool, Bool) -> Bool, _ symbol: String) -> Expr {
  return Expr.fun { (exprs: [Expr], env: Env) -> EvalResult in
    if let firstArg = exprs.first, let secondArg = exprs.dropFirst().first {
      return eval(firstArg, env).map { firstRes in
        firstRes.0
      }.flatMap { firstRes in
        eval(secondArg, env).map { secondRes in (firstRes, secondRes.0) }
      }.flatMap { args in
        switch (args.0, args.1) {
        case (.bool(let left), .bool(let right)):
          return .success((.bool(opr(left, right)), env))
        default:
          return makeEvalError(
            "Both args to \(symbol) need to be boolean, got: \(args.0) and \(args.1)"
          )
        }
      }
    } else {
      return makeEvalError("\(symbol) takes 2 arguments.")
    }
  }
}
public let stdLib: Env = [
  "+": intIntOperator({ $0 + $1 }, "+"),
  "str-append": stringStringOperator({ $0 + $1 }, "str-append"),
  "-": intIntOperator({ $0 - $1 }, "-"),
  "*": intIntOperator({ $0 * $1 }, "*"),
  "/": intIntOperator({ $0 / $1 }, "/"),
  "and": boolBoolOperator({ $0 && $1 }, "and"),
  "or": boolBoolOperator({ $0 || $1 }, "or"),
  "eq": comparisonOperator("eq") { $0 == $1 },
  "<": comparisonOperator("<") { a, b in
    switch (a, b) {
    case (.number(let left), .number(let right)):
      return left < right
    case _:
      return false
    }
  },
  ">": comparisonOperator(">") { a, b in
    switch (a, b) {
    case (.number(let left), .number(let right)):
      return left > right
    case _:
      return false
    }
  },
  ">=": comparisonOperator(">=") { a, b in
    switch (a, b) {
    case (.number(let left), .number(let right)):
      return left >= right
    case _:
      return false
    }
  },
  "<=": comparisonOperator("<=") { a, b in
    switch (a, b) {
    case (.number(let left), .number(let right)):
      return left <= right
    case _:
      return false
    }
  },
  "let": Expr.fun { (exprs, originalEnv) in
    let args = (exprs.first, exprs.dropFirst().first)

    guard case (let first as Expr, let second as Expr) = args, exprs.count == 2 else {
      return makeEvalError(
        "Expected two args to let, one list of bindings and one expr to evaluate, found: \(exprs)")
    }

    // (define (subsets s)
    //   (if (null? s)
    //       (list nil)
    //       (let
    //         ((rest (subsets (cdr s))))
    //         (append rest (map <??> rest)))))

    return makeEvalError("NYI")
  },
  "null": Expr.null,
  "car": Expr.fun { (exprs: [Expr], env: Env) in
    unapply(exprs).map { (head, _) in
      head
    }.flatMapError { _ in
      .failure(
        EvalError(

          message: ("car must be applied to 1 argument.")))
    }.flatMap { firstArgExpr in
      eval(firstArgExpr, env)
    }.flatMap { (firstArgEvaled, _) in
      switch firstArgEvaled {
      case Expr.list(let list):
        return unapply(list).map { (head, _) in
          return (head, env)
        }.flatMapError { _ in
          return .success((Expr.null, env))
        }
      case let other:
        return makeEvalError("Can only apply car to list, got: \(other)")
      }
    }
  },
  "cdr": Expr.fun { (exprs: [Expr], env: Env) in
    unapply(exprs).map { (head, _) in
      head
    }.flatMapError { _ in
      .failure(
        EvalError(
          message: ("cdr must be applied to 1 argument.")
        ))
    }.flatMap { firstArgExpr in
      eval(firstArgExpr, env)
    }.flatMap { (firstArgEvaled, _) in
      switch firstArgEvaled {
      case Expr.list(let list):
        return unapply(list).map { (_, tail) in
          return (Expr.list(tail), env)
        }.flatMapError { _ in
          return .success((Expr.list([]), env))
        }
      case let other:
        return makeEvalError("Can only apply cdr to list, got: \(other)")
      }
    }
  },
  "true": Expr.bool(true),
  "false": Expr.bool(false),
  "cond": Expr.fun { (exprs: [Expr], env: Env) in
    return
      (exprs.reduce(
        .success(Expr.null),
        {
          (acc: Result<Expr, EvalError>, condExpr: Expr) in
          return acc.flatMap { (accExpr: Expr) in
            switch accExpr {
            case Expr.null:
              switch condExpr {
              case Expr.list(let condExprList):
                if let predExpr = condExprList.first, let thenExpr = condExprList.dropFirst().first
                {
                  return eval(predExpr, env).flatMap { (evaledPredExpr, _) in
                    switch evaledPredExpr {
                    case Expr.bool(true):
                      return eval(thenExpr, env).flatMap {
                        let result = Result<Expr, EvalError>.success($0.0)
                        return result
                      }
                    default:
                      return .success(Expr.null)
                    }
                  }
                } else {
                  return .failure(
                    EvalError(
                      message:
                        "Each argument to cond should be pair of (predExpr thenExpr), got: \(condExpr)"
                    )
                  )
                }
              default:
                return .failure(
                  EvalError(
                    message:
                      "Each argument to cond should be pair of (predExpr thenExpr), got: \(condExpr)"
                  )
                )
              }
            // continue
            case let value:
              return .success(value)
            }
          }
        })).flatMap {
        return .success(($0, env))
      }

  },
  "cons": Expr.fun { (exprs: [Expr], env: Env) in
    if let firstArg = exprs.first, let secondArg = exprs.dropFirst().first {
      return eval(firstArg, env).flatMap { firstRes in
        return eval(secondArg, env).flatMap { secondRes in
          switch secondRes.0 {
          case .list(let list):
            return .success((Expr.list([firstRes.0] + list), env))
          default:
            return makeEvalError("Second arg to cons must be list, got \(firstArg)")
          }
        }
      }
    } else {
      return makeEvalError("takes 2 arguments, an element and a list.")
    }
  },
  "def": Expr.fun { (exprs: [Expr], env: Env) in
    if exprs.count != 2 {
      return makeEvalError("\"def\" takes 2 arguments.")
    }
    return unapply(exprs).flatMap { (head, tail) in
      switch head {
      case Expr.variable(let variableName):
        if env[variableName] != nil {
          return makeEvalError("\"\(variableName)\" is already defined in the environment.")
        } else {
          return unapply(tail).flatMap { (head2, _) in
            .success((variableName, head2))
          }
        }
      default:
        return makeEvalError("First arg to def must be symbol.")
      }
    }.flatMap { (symbol, expr) -> EvalResult in
      eval(expr, env).flatMap { evaluatedExpr, _ in
        .success(
          (
            Expr.null,
            env.merging([symbol: evaluatedExpr]) { env, _ in env }
          ))
      }
    }
  },
  "print": Expr.fun { (exprs: [Expr], env: Env) in
    return unapply(exprs)
      .flatMap { (head, tail) in
        switch tail.count {
        case 0:
          return .success(head)
        default: return makeEvalError("print takes only one argument.")
        }
      }.flatMap {
        eval($0, env)
      }.flatMap {
        .success($0.0)
      }.flatMap { value in
        switch value {
        case .string(let a):
          print(a)
        default:
          print(value)
        }
        return .success((Expr.null, env))
      }
  },
  "quote": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .success((let head, let tail)) = unapply(exprs) else {
      return makeEvalError("Cannot quote empty list")
    }
    if tail.count > 0 {
      return makeEvalError("quote takes 1 argument only.")
    }
    return .success((head, env))
  },
  "fn": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .success((let head, let tail)) = unapply(exprs) else {
      return makeEvalError("Missing first arg to fn, list of symbols")
    }
    guard case .success((let body, _)) = unapply(tail) else {
      return makeEvalError("Second arg to fn undefined, should be list.")
    }
    guard case .success(let symbols) = getSymbolsFromListExpr(head) else {
      return makeEvalError("woops")
    }

    guard case .list(let bodyList) = body else {
      return makeEvalError("Second argument to fn should be a list, got: \(body)")
    }

    return Result.success(
      (
        Expr.fun({ (fnArgs, fnEnv) in
          if fnArgs.count != symbols.count {
            return makeEvalError(
              "Wrong nr of args to fn, got \(fnArgs.count) needed \(symbols.count)")
          }
          let emptyEnv: Env = [:]
          // Evaluate all fnArgs
          let argsEnv: Result<Env, EvalError> = zip(symbols, fnArgs).reduce(
            .success(emptyEnv),
            { (acc: Result<Env, EvalError>, kvs: (String, Expr)) in
              let kvsExprEvalResult = eval(kvs.1, fnEnv)
              return kvsExprEvalResult.flatMap { kvsExprEvalResult in
                return acc.flatMap { accEvalResult in
                  return .success(
                    accEvalResult.merging(
                      [kvs.0: kvsExprEvalResult.0], uniquingKeysWith: { _, kvs in kvs }))
                }
              }
            })
          return argsEnv.flatMap { argsEnv in
            let applicationEnv: Env = argsEnv.merging(
              fnEnv,
              uniquingKeysWith: { argsEnv, _ in argsEnv }
            )
            let bodyApplyResult = eval(Expr.list(bodyList), applicationEnv)
            return bodyApplyResult.flatMap { result in
              .success((result.0, fnEnv))
            }
          }
        }), env
      ))
  },
]
