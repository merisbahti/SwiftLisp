func intIntOperator(_ opr: @escaping (Float64, Float64) -> Float64, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }

    let exprsVerified: Result<[Float64], EvalError> = exprsEvaled.reduce(.success([])) {
      acc, curr in
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

func def(_ exprs: [Expr], _ env: Env) -> EvalResult {
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
}

func defineFn(_ allSymbols: [String], _ body: [Expr], _ env: Env) -> Result<Expr, EvalError> {
  let isVariadic = allSymbols.dropLast().last == "."
  let variadicSymbol: String? = isVariadic ? allSymbols.last : .none
  let symbols = isVariadic ? allSymbols.dropLast().dropLast() : allSymbols

  let newFn = Expr.fun({ (fnArgs, fnEnv) in
    if isVariadic ? fnArgs.count < symbols.count : fnArgs.count != symbols.count {
      return makeEvalError(
        "Wrong nr of args to fn, got \(fnArgs.count) needed \(symbols.count)")
    }

    let argsEvaledResult = resultsArray(fnArgs.map { arg in eval(arg, fnEnv).map { $0.0 } })

    guard case .success(let argsEvaled) = argsEvaledResult else {
      return argsEvaledResult.map { _ in (.null, env) }
    }

    let formalArgsEnv: Env = Dictionary(uniqueKeysWithValues: zip(symbols, argsEvaled))
    let variadicArgEnv: Env =
      (variadicSymbol.map { vKey in
        [vKey: exprsToPairs(Array(argsEvaled.dropFirst(symbols.count)))]
      }) ?? [:]

    let argsEnv =
      fnEnv
      .merging(formalArgsEnv, uniquingKeysWith: { (_, b) in b })
      .merging(variadicArgEnv, uniquingKeysWith: { (_, b) in b })

    return evalWithEnv(body, argsEnv).map { ($0.0, env) }

  })
  return Result.success(newFn)
}

func defineMacro(_ exprs: [Expr], _ env: Env) -> Result<(Expr, Env), EvalError> {
  guard case (.some(let definee), .some(let body)) = (exprs.first, exprs.dropFirst().first),
    exprs.count == 2
  else {
    return makeEvalError("macros takes two args")
  }
  guard case .success(let allSymbols) = getSymbolsFromListExpr(definee), allSymbols.count > 0 else {
    return makeEvalError("Expected list symbols as first arg, but found: \(definee) ")
  }

  let isVariadic = allSymbols.dropLast().last == "."
  let variadicSymbol: String? = isVariadic ? allSymbols.last : .none

  let macroName = allSymbols.first!
  let symbols = isVariadic ? allSymbols.dropFirst().dropLast().dropLast() : allSymbols.dropFirst()

  guard case .pair(let bodyList) = body else {
    return makeEvalError(
      "Second argument to macro definition should be a list, got: \(body)"
    )
  }

  let newFn = Expr.fun({ (fnArgs, fnEnv) in
    if isVariadic ? fnArgs.count < symbols.count : fnArgs.count != symbols.count {
      return makeEvalError(
        "Wrong nr of args to \(macroName), got \(fnArgs.count) needed \(symbols.count)")
    }

    let formalArgsEnv: Env = Dictionary(uniqueKeysWithValues: zip(symbols, fnArgs))
    let variadicArgEnv: Env =
      (variadicSymbol.map { vKey in
        [vKey: exprsToPairs(Array(fnArgs.dropFirst(symbols.count)))]
      }) ?? [:]

    let argsEnv =
      fnEnv
      .merging(formalArgsEnv, uniquingKeysWith: { (_, b) in b })
      .merging(variadicArgEnv, uniquingKeysWith: { (_, b) in b })

    return eval(.pair(bodyList), argsEnv).map { ($0.0, fnEnv) }
  })

  return Result.success(
    (newFn, env.merging([(macroName, newFn)], uniquingKeysWith: { (_, b) in b })))
}

func unaryMatcherFun(_ name: String, _ fn: @escaping (_ expr: Expr) -> Bool) -> Expr {
  return Expr.fun { (exprs, env) in
    guard case .success((let head, let x)) = unapply(exprs), x.count == 0 else {
      return makeEvalError("\(name) takes two args, found: \(exprs)")
    }
    return eval(head, env).map {
      (.bool(fn($0.0)), env)
    }
  }
}

public let stdLib: Env = [
  "pair?":
    unaryMatcherFun("pair?") { x in
      switch x {
      case .pair(_): return true
      case .null: return true
      default: return false
      }
    },
  "number?":
    unaryMatcherFun("number?") { x in
      switch x {
      case .number(_): return true
      default: return false
      }
    },
  "string?":
    unaryMatcherFun("string?") { x in
      switch x {
      case .string(_): return true
      default: return false
      }
    },
  "bool?":
    unaryMatcherFun("bool?") { x in
      switch x {
      case .bool(_): return true
      default: return false
      }
    },
  "defMacro": .fun(defineMacro),
  "+": intIntOperator({ $0 + $1 }, "+"),
  "%": intIntOperator({ $0.truncatingRemainder(dividingBy: $1) }, "%"),
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
  "else": Expr.bool(true),
  "let": Expr.fun { (exprs, originalEnv) in
    let args = (exprs.first, exprs.dropFirst().first)

    guard case (let .pair(first), .some(let expr)) = args, exprs.count == 2 else {
      return makeEvalError(
        "Expected two args to let, one list of bindings and one expr to evaluate, found: \(exprs)")
    }

    func extractBinding(_ bindingMaybe: Expr, _ env: Env) -> Result<(String, Expr), EvalError> {
      let err: Result<(String, Expr), EvalError> = makeEvalError(
        "Expected binding but found: \(bindingMaybe)")
      guard case .pair((.variable(let variableName), .pair((let value, .null)))) = bindingMaybe
      else {
        return err
      }
      return eval(value, env).map { (variableName, $0.0) }
    }

    let pairs = collectPairs(.pair(first))

    let bindingsResult: Result<[(String, Expr)], EvalError> = pairs.flatMap {
      exprs in
      resultsArray(
        exprs.map { extractBinding($0, originalEnv) }
      )
    }

    guard case .success(let bindings) = bindingsResult else {
      return bindingsResult.map { x in (.null, originalEnv) }
    }

    let newEnv = originalEnv.merging(bindings, uniquingKeysWith: { (_, b) in b })

    return eval(expr, newEnv).map { (expr, _) in (expr, originalEnv) }
  },
  "null": Expr.null,
  "car": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .some(let first) = exprs.first, exprs.count == 1 else {
      return makeEvalError("car must be applied to 1 argument.")
    }
    let evaled = eval(first, env)

    guard case .success((.pair((let pair)), _)) = evaled else {
      return makeEvalError("Can only apply car to pair, got: \(evaled)")
    }
    return .success((pair.0, env))
  },
  "cdr": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .some(let first) = exprs.first, exprs.count == 1 else {
      return makeEvalError("cdr must be applied to 1 argument.")
    }
    let evaled = eval(first, env)
    guard case .success((.pair((let pair)), _)) = evaled else {
      return makeEvalError("Can only apply cdr to pair, got: \(evaled)")
    }
    return .success((pair.1, env))
  },
  "true": Expr.bool(true),
  "false": Expr.bool(false),
  "cond": Expr.fun { (exprs: [Expr], env: Env) in
    let maybeResult = exprs.reduce(
      Optional.none
    ) {
      (acc: Result<Expr, EvalError>?, condExpr: Expr) in
      if case .some(let cons) = acc {
        return acc
      }

      switch condExpr {
      case Expr.pair((let predExpr, .pair((let thenExpr, .null)))):
        switch eval(predExpr, env).map({ $0.0 }) {
        case .success(Expr.bool(true)):
          return .some(
            eval(thenExpr, env).flatMap {
              let result = Result<Expr, EvalError>.success($0.0)
              return result
            })
        default:
          return .none
        }

      default:
        return .some(
          makeEvalError(
            "Each argument to cond should be pair of (predExpr thenExpr), got: \(condExpr)"
          )
        )
      }
    }
    return (maybeResult ?? .success(.null)).map { ($0, env) }

  },
  "cons": Expr.fun { (exprs: [Expr], env: Env) in
    guard let firstArg = exprs.first, let secondArg = exprs.dropFirst().first else {
      return makeEvalError("takes 2 arguments, an element and a list.")
    }

    let firstArgEvalResult = eval(firstArg, env)
    guard case .success((let firstArgEvaled, _)) = firstArgEvalResult else {
      return firstArgEvalResult
    }

    let secondArgEvalResult = eval(secondArg, env)
    guard case .success((let secondArgEvaled, _)) = secondArgEvalResult else {
      return secondArgEvalResult
    }

    return .success((.pair((firstArgEvaled, secondArgEvaled)), env))
  },
  "eval": Expr.fun { (exprs, env) in
    if exprs.count != 1 {
      return makeEvalError("Expr takes one arg, found: \(exprs)")
    }
    guard let head = exprs.first else {
      return makeEvalError("Expr takes one arg, found: \(exprs)")
    }

    let res =
      eval(head, env).flatMap { eval($0.0, env) }
    return res

  },
  "def": Expr.fun { (exprs, env) in def(exprs, env) },
  "print": Expr.fun { (exprs: [Expr], env: Env) in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }
    return resultsArray(exprsEvaled).flatMap { exprs in
      let formatted = exprs.reduce("") { acc, curr in
        switch curr.0 {
        case .string(let a):
          return "\(acc)\(a)"
        default:
          return "\(acc)\(curr.0)"
        }
      }
      print(formatted)
      return .success((Expr.null, env))
    }
  },
  "list": Expr.fun { (exprs: [Expr], env: Env) in
    let exprsEvaled = resultsArray(exprs.map { expr in eval(expr, env).map { $0.0 } })
    return exprsEvaled.map { exprs in (exprsToPairs(exprs), env) }
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
  "define": Expr.fun { (exprs, env) in
    guard case (.some(let definee), let body) = (exprs.first, exprs.dropFirst()),
      exprs.count > 1
    else {
      return makeEvalError("define takes two args")
    }
    if case (.variable(let symbol)) = definee {
      return def(exprs, env)
    }
    guard case .success(let allSymbols) = getSymbolsFromListExpr(definee), allSymbols.count > 0
    else {
      return makeEvalError(
        "define's first arg should be a symbol or list of symbols (at least 1 symbols), found: \(definee)"
      )
    }

    let fnName = allSymbols.first!
    let fnDef = defineFn(Array(allSymbols.dropFirst()), Array(body), env)
    guard case let .success(newFn) = fnDef else {
      return fnDef.map({ ($0, env) })
    }

    return Result.success(
      (
        newFn, env.merging([(fnName, newFn)], uniquingKeysWith: { (_, b) in b })
      ))
  },
  "fn": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .success((let head, let body)) = unapply(exprs) else {
      return makeEvalError("Missing first arg to fn, list of symbols")
    }
    let symbols = getSymbolsFromListExpr(head)
    guard case .success(let symbols) = getSymbolsFromListExpr(head) else {
      return symbols.map { _ in (.null, env) }
    }

    return defineFn(symbols, body, env).map { ($0, env) }
  },
]
