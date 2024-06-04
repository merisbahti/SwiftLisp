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
  indirect case pair((Expr, Expr))
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
    case (.pair((let car, let cdr)), .pair((let car2, let cdr2))):
      return car == car2 && cdr == cdr2
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
public class Env {
  var baseEnv: Env?
  var myEnv: [String: Expr]
  init(_ initialEnv: [String: Expr], baseEnv baseEnv: Env? = .none) {
    self.baseEnv = baseEnv
    self.myEnv = initialEnv
  }

  func get(key: String) -> Expr? {
    return myEnv[key] ?? (baseEnv.flatMap { base in base.get(key: key) })
  }
}

public func makeEvalError<A>(_ msg: String) -> Result<A, EvalError> {
  .failure(EvalError(message: msg))
}

let getSymbolsFromListExpr: (Expr) -> Result<[String], EvalError> = { exprs in
  switch exprs {
  case .pair((.variable(let a), .null)): return .success([a])
  case .pair((.variable(let a), let expr)):
    return getSymbolsFromListExpr(expr).map { $0.prepending(a) }
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

func collectPairs(_ expr: Expr, _ acc: [Expr] = []) -> Result<[Expr], EvalError> {
  switch expr {
  case .pair((let car, .null)): return .success(acc.appending(car))
  case .pair((let car, let cdr)): return collectPairs(cdr, acc.appending(car))
  case .null: return .success([])
  case let x: return .success(acc.appending(x))
  }
}

public func eval(_ expr: Expr, _ env: Env) -> EvalResult {
  switch expr {
  case .pair((let car, let cdr)):
    let headResult = eval(car, env)
    guard case .success((.fun(let carEvaled), _)) = headResult else {
      switch headResult {
      case .failure(let evalError): return .failure(evalError)
      default: return makeEvalError("\(car) is not a function (in pair \(expr))")
      }
    }
    let pairs = collectPairs(cdr)
    guard case .success(let args) = pairs else {
      return pairs.map { _ in (.null, env) }
    }
    return carEvaled(args, env)
  case .variable(let val):
    if let expr = env.get(key: val) {
      return .success((expr, env))
    } else {
      return .failure(EvalError(message: "Variable not found: \(val)"))
    }
  default:
    return .success((expr, env))
  }
}

public func evalWithEnv(_ exprs: [Expr], _ env: Env) -> Result<(Expr, Env), EvalError> {
  return unapply(exprs).flatMap { (head, tail) in
    return tail.reduce(
      eval(head, env),
      { res, expr in
        return res.flatMap { _, newEnv in eval(expr, newEnv) }
      })
  }
}

public func eval(_ exprs: [Expr]) -> Result<Expr, EvalError> {
  let newEnv = Env([:], baseEnv: stdLib)
  return evalWithEnv(exprs, newEnv).map { $0.0 }
}
