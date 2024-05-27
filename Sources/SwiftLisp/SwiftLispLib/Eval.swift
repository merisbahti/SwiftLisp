public struct EvalError: Error {
  let message: String
}

extension EvalError: Equatable {
  public static func == (lhs: EvalError, rhs: EvalError) -> Bool {
    return lhs.message == rhs.message
  }
}

public enum Expr {
  case number(Float64)
  case string(String)
  case list([Expr])
  case variable(String)
  case fun(([Expr], Env) -> EvalResult)
  case bool(Bool)
  case null
}

extension Expr: Equatable {
  public static func == (lhs: Expr, rhs: Expr) -> Bool {
    switch (lhs, rhs) {
    case (.number(let nr1), .number(let nr2)):
      return nr1 == nr2
    case (.list(let list1), .list(let list2)):
      return list1 == list2
    case (.bool(let bool1), .bool(let bool2)):
      return bool1 == bool2
    case (.string(let string1), .string(let string2)):
      return string1 == string2
    case (.null, .null):
      return true
    default:
      return false
    }
  }
}

public typealias EvalResult = Result<(Expr, Env), EvalError>
public typealias Env = [String: Expr]

public func makeEvalError<A>(_ msg: String) -> Result<A, EvalError> {
  .failure(EvalError(message: msg))
}

let getSymbolsFromListExpr: (Expr) -> Result<[String], EvalError> = { exprs in
  switch exprs {
  case .list(let list):
    return list.reduce(.success([])) { acc, expr in
      return acc.flatMap { resultAcc in
        switch expr {
        case .variable(let str):
          return .success(resultAcc + [str])
        default:
          return .failure(EvalError(message: "All members in expr must be symbol."))
        }
      }
    }
  case let other:
    return .failure(EvalError(message: "Expected list, got: \(other)"))
  }
}
func unapply<T>(_ list: [T]) -> Result<(T, [T]), EvalError> {
  let head = list.first
  let tail = list.dropFirst()
  if let head = head {
    return .success((head, Array(tail)))
  } else {
    return .failure(EvalError(message: ("Failure to unpack list.")))
  }
}

public func eval(_ expr: Expr, _ env: Env) -> EvalResult {
  switch expr {
  case .list(let tokenList):
    guard case .success((let head, let tail)) = unapply(tokenList) else {
      return makeEvalError("Cannot evaluate empty list: \(tokenList)")
    }

    let evalResult = eval(head, env)
    guard case .success((.fun(let fn), _)) = evalResult else {
      switch evalResult {
      case .failure(let failure): return makeEvalError(failure.message)
      case .success((let nonMatchingExpr, _)):
        return makeEvalError(
          "car of list is not a function, found: \(nonMatchingExpr) in list \(expr)")
      }
    }

    return fn(tail, env)
  case .variable(let val):
    if let expr = env[val] {
      return .success((expr, env))
    } else {
      return .failure(EvalError(message: "Variable not found: \(val)"))
    }
  case .fun:
    return .failure(EvalError(message: "Cannot evaluate function."))
  case .null:
    return .failure(EvalError(message: "Can't eval null"))
  default:
    return .success((expr, env))
  }
}

public func evalWithEnv(_ exprs: [Expr], _ env: Env) -> Result<(Expr, Env), EvalError> {
  return unapply(exprs).flatMap { (head, tail) in
    return tail.reduce(
      eval(head, env),
      { res, expr in
        return res.flatMap { _, newEnv in return eval(expr, newEnv) }
      })
  }
}

public func eval(_ exprs: [Expr]) -> Result<Expr, EvalError> {
  return evalWithEnv(exprs, stdLib).map { $0.0 }
}
