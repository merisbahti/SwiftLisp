func intIntOperator(_ opr: @escaping (Float64, Float64) -> Float64, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }

    let exprsVerified: Result<[Float64], EvalError> = exprsEvaled.reduce(.success([])) {
      acc, curr in
      switch (acc, curr) {
      case (.failure(let evalError), _): return .failure(evalError)
      case (.success(let acc), .success(.number(let nr))):
        return .success(acc.appending(nr))
      case (_, .success(let expr)):
        return makeEvalError("Error evaling \(symbol), expected numbers but found: \(expr)")
      case (_, .failure(let evalFailure)):
        return .failure(evalFailure)
      }
    }

    guard case let .success(ints) = exprsVerified else {
      return exprsVerified.map { _ in .number(0) }
    }

    let a = unapply(ints).map { (head, tail) in
      Expr.number(tail.reduce(head) { (acc, curr) in opr(acc, curr) })
    }

    return a
  })
}
func stringStringOperator(_ opr: @escaping (String, String) -> String, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }

    let exprsVerified: Result<[String], EvalError> = exprsEvaled.reduce(.success([])) {
      acc, curr in
      switch (acc, curr) {
      case (.failure(let evalError), _): return .failure(evalError)
      case (.success(let acc), .success(.string(let nr))):
        return .success(acc.appending(nr))
      case (_, .success(let expr)):
        return makeEvalError("Error evaling \(symbol), expected strings but found: \(expr)")
      case (_, .failure(let evalFailure)):
        return .failure(evalFailure)
      }
    }

    guard case let .success(strings) = exprsVerified else {
      return exprsVerified.map { _ in .null }
    }

    let a = unapply(strings).map { (head, tail) in
      Expr.string(tail.reduce(head) { (acc, curr) in opr(acc, curr) })
    }

    return a
  })
}

func comparisonOperator(_ symbol: String, _ opr: @escaping (Expr, Expr) -> Bool) -> Expr {
  return Expr.fun { (exprs: [Expr], env: Env) -> EvalResult in
    if let firstArg = exprs.first, let secondArg = exprs.dropFirst().first {
      return eval(firstArg, env).flatMap { firstRes in
        eval(secondArg, env).map { secondRes in (firstRes, secondRes) }
      }.flatMap { args in
        .success(.bool(opr(args.0, args.1)))
      }
    } else {
      return makeEvalError("\(symbol) takes 2 arguments.")
    }
  }
}

func boolBoolOperator(_ opr: @escaping (Bool, Bool) -> Bool, _ symbol: String) -> Expr {
  return Expr.fun({ (exprs: [Expr], env: Env) -> EvalResult in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }

    let exprsVerified: Result<[Bool], EvalError> = exprsEvaled.reduce(.success([])) {
      acc, curr in
      switch (acc, curr) {
      case (.failure(let evalError), _): return .failure(evalError)
      case (.success(let acc), .success(.bool(let nr))):
        return .success(acc.appending(nr))
      case (_, .success(let expr)):
        return makeEvalError("Error evaling \(symbol), expected bool but found: \(expr)")
      case (_, .failure(let evalFailure)):
        return .failure(evalFailure)
      }
    }

    guard case let .success(bools) = exprsVerified else {
      return exprsVerified.map { _ in .number(0) }
    }

    let a = unapply(bools).map { (head, tail) in
      Expr.bool(tail.reduce(head) { (acc, curr) in opr(acc, curr) })
    }

    return a
  })
}

func def(_ exprs: [Expr], _ env: Env) -> EvalResult {
  if exprs.count != 2 {
    return makeEvalError("\"def\" takes 2 arguments.")
  }
  return unapply(exprs).flatMap { (head, tail) in
    switch head {
    case Expr.variable(let variableName, _):
      return unapply(tail).flatMap { (head2, _) in
        .success((variableName, head2))
      }
    default:
      return makeEvalError("First arg to def must be symbol.")
    }
  }.flatMap { (symbol, expr) -> EvalResult in
    eval(expr, env).flatMap { evaluatedExpr in
      env.myEnv.updateValue(evaluatedExpr, forKey: symbol)

      return .success(Expr.null)
    }
  }
}

func defineFn(
  _ allSymbols: [String], _ body: [Expr], _ env: Env, _ sourceContext: SourceContext? = .none
) -> Result<Expr, EvalError> {
  let isVariadic = allSymbols.dropLast().last == "."
  let variadicSymbol: String? = isVariadic ? allSymbols.last : .none
  let symbols = isVariadic ? allSymbols.dropLast().dropLast() : allSymbols

  let newFn = Expr.fun({ (fnArgs, fnEnv) in
    if isVariadic ? fnArgs.count < symbols.count : fnArgs.count != symbols.count {
      let extraSourceInfo =
        sourceContext.flatMap { $0.renderSourceContext() }.map {
          "\nFunction was defined here:\($0)"
        } ?? ""

      return makeEvalError(
        "Wrong nr of args to fn, got \(fnArgs.count) needed \(symbols.count) \(extraSourceInfo)")
    }

    let argsEvaledResult = resultsArray(fnArgs.map { arg in eval(arg, fnEnv) })

    guard case .success(let argsEvaled) = argsEvaledResult else {
      return argsEvaledResult.map { _ in .null }
    }

    let formalArgsEnv: Env = Env(
      Dictionary(uniqueKeysWithValues: zip(symbols, argsEvaled)),
      baseEnv: env
    )
    let variadicArgEnv: Env =
      Env(
        variadicSymbol.map { vKey in
          [vKey: exprsToPairs(Array(argsEvaled.dropFirst(symbols.count)))]
        } ?? [:], baseEnv: .some(formalArgsEnv)

      )
    return evalWithEnv(body, variadicArgEnv)

  })
  return Result.success(newFn)
}

func defineMacro(_ exprs: [Expr], _ env: Env) -> Result<Expr, EvalError> {
  guard case (.some(let definee), .some(let body)) = (exprs.first, exprs.dropFirst().first),
    exprs.count == 2
  else {
    return makeEvalError("macros takes two args")
  }
  guard case .success(let allSymbols) = getSymbolsFromListExpr(definee).map({ $0.map { $0.0 } }),
    allSymbols.count > 0
  else {
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

    let formalArgsEnv: Env = Env(
      Dictionary(uniqueKeysWithValues: zip(symbols, fnArgs)),
      baseEnv: fnEnv  // bit confusing... macros expand where they are called.
    )
    let variadicArgEnv: Env =
      Env(
        variadicSymbol.map { vKey in
          [vKey: exprsToPairs(Array(fnArgs.dropFirst(symbols.count)))]
        } ?? [:], baseEnv: .some(formalArgsEnv)

      )

    return eval(.pair(bodyList), variadicArgEnv)
  })

  env.myEnv.updateValue(newFn, forKey: macroName)

  return Result.success(newFn)
}

func unaryMatcherFun(_ name: String, _ fn: @escaping (_ expr: Expr) -> Bool) -> Expr {
  return Expr.fun { (exprs, env) in
    guard case .success((let head, let x)) = unapply(exprs), x.count == 0 else {
      return makeEvalError("\(name) takes two args, found: \(exprs)")
    }
    return eval(head, env).map {
      .bool(fn($0))
    }
  }
}

public let stdLib: Env = Env([
  "symbol?":
    unaryMatcherFun("symbol?") { x in
      switch x {
      case .variable(_, _): return true
      default: return false
      }
    },
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
  "error": Expr.fun { (exprs, env) in
    let arg = exprs.first

    guard case .some(let arg) = exprs.first, exprs.count == 1 else {
      return makeEvalError(
        "Expected one arg to fail, found: \(exprs)")
    }

    switch eval(arg, env) {
    case .failure(let evalError): return .failure(evalError)
    case .success(.string(let str)): return makeEvalError(str)
    default: return makeEvalError("woops")
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
      guard case .pair((.variable(let variableName, _), .pair((let value, .null)))) = bindingMaybe
      else {
        return err
      }
      return eval(value, env).map { (variableName, $0) }
    }

    let pairs = collectPairs(.pair(first))

    let bindingsResult: Result<[(String, Expr)], EvalError> = pairs.flatMap {
      exprs in
      resultsArray(
        exprs.map { extractBinding($0, originalEnv) }
      )
    }

    guard case .success(let bindings) = bindingsResult else {
      return bindingsResult.map { x in .null }
    }

    let newEnv = Env(Dictionary(uniqueKeysWithValues: bindings), baseEnv: originalEnv)

    return eval(expr, newEnv)
  },
  "null": Expr.null,
  "car": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .some(let first) = exprs.first, exprs.count == 1 else {
      return makeEvalError("car must be applied to 1 argument.")
    }
    let evaled = eval(first, env)

    guard case .success(.pair((let pair))) = evaled else {
      switch evaled {
      case .failure(let evalError): return .failure(evalError)
      case .success(let otherExpr):
        return makeEvalError("Can only apply car to pair, got: \(otherExpr)")
      }
    }
    return .success(pair.0)
  },
  "cdr": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .some(let first) = exprs.first, exprs.count == 1 else {
      return makeEvalError("cdr must be applied to 1 argument.")
    }
    let evaled = eval(first, env)
    guard case .success(.pair((let pair))) = evaled else {
      switch evaled {
      case .failure(let evalError): return .failure(evalError)
      case .success(let otherExpr):
        return makeEvalError("Can only apply cdr to pair, got: \(otherExpr)")
      }
    }
    return .success(pair.1)
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
        switch eval(predExpr, env) {
        case .success(Expr.bool(true)):
          return .some(
            eval(thenExpr, env).flatMap {
              let result = Result<Expr, EvalError>.success($0)
              return result
            })
        case .failure(let evalError): return .failure(evalError)
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
    return (maybeResult ?? .success(.null))
  },
  "cons": Expr.fun { (exprs: [Expr], env: Env) in
    guard let firstArg = exprs.first, let secondArg = exprs.dropFirst().first else {
      return makeEvalError("takes 2 arguments, an element and a list.")
    }

    let firstArgEvalResult = eval(firstArg, env)
    guard case .success(let firstArgEvaled) = firstArgEvalResult else {
      return firstArgEvalResult
    }

    let secondArgEvalResult = eval(secondArg, env)
    guard case .success(let secondArgEvaled) = secondArgEvalResult else {
      return secondArgEvalResult
    }

    return .success(.pair((firstArgEvaled, secondArgEvaled)))
  },
  "eval": Expr.fun { (exprs, env) in
    guard let head = exprs.first, exprs.count == 1 else {
      return makeEvalError("eval takes one arg, found: \(exprs)")
    }

    let res =
      eval(head, env).flatMap { eval($0, env) }

    return res
  },
  "def": Expr.fun(def),
  "print": Expr.fun { (exprs: [Expr], env: Env) in
    let exprsEvaled: [EvalResult] = exprs.map { expr in eval(expr, env) }
    return resultsArray(exprsEvaled).flatMap { exprs in
      let formatted = exprs.reduce("") { acc, curr in
        switch curr {
        case .string(let a):
          return "\(acc)\(a)"
        default:
          return "\(acc)\(curr)"
        }
      }
      print(formatted)
      return .success(Expr.null)
    }
  },
  "list": Expr.fun { (exprs: [Expr], env: Env) in
    let exprsEvaled = resultsArray(exprs.map { expr in eval(expr, env) })
    return exprsEvaled.map { exprs in exprsToPairs(exprs) }
  },
  "quote": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .success((let head, let tail)) = unapply(exprs) else {
      return makeEvalError("Cannot quote empty list")
    }
    if tail.count > 0 {
      return makeEvalError("quote takes 1 argument only.")
    }
    return .success(head)
  },
  "define": Expr.fun { (exprs, env) in
    guard case (.some(let definee), let body) = (exprs.first, exprs.dropFirst()),
      exprs.count > 1
    else {
      return makeEvalError("define takes two args")
    }
    if case (.variable(let symbol, _)) = definee {
      return def(exprs, env)
    }
    guard case .success(let allSymbols) = getSymbolsFromListExpr(definee), allSymbols.count > 0
    else {
      return makeEvalError(
        "define's first arg should be a symbol or list of symbols (at least 1 symbols), found: \(definee)"
      )
    }

    let fnName = allSymbols.first!
    let fnDef = defineFn(Array(allSymbols.map { $0.0 }.dropFirst()), Array(body), env, fnName.1)
    guard case let .success(newFn) = fnDef else {
      return fnDef
    }

    env.myEnv.updateValue(newFn, forKey: fnName.0)

    return Result.success(newFn)
  },
  "fn": Expr.fun { (exprs: [Expr], env: Env) in
    guard case .success((let head, let body)) = unapply(exprs) else {
      return makeEvalError("Missing first arg to fn, list of symbols")
    }
    let symbols = getSymbolsFromListExpr(head)
    guard case .success(let symbols) = getSymbolsFromListExpr(head) else {
      return symbols.map { _ in .null }
    }
    return defineFn(symbols.map { $0.0 }, body, env, .none)
  },
])
