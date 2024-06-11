import SwiftParsec

public struct EvalError: Error {
  public let message: String
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
  case variable(String, SourceContext? = .none)
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
    case (.variable(let lhs, _), .variable(let rhs, _)):
      return lhs == rhs
    case (.null, .null):
      return true
    default:
      return false
    }
  }
}

public typealias EvalResult = Result<Expr, EvalError>
public class Env {
  var baseEnv: Env?
  var myEnv: [String: Expr]
  public init(_ initialEnv: [String: Expr], baseEnv base: Env? = .none) {
    self.baseEnv = base
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
  case .pair((.variable(let a, _), .null)): return .success([a])
  case .pair((.variable(let a, _), let expr)):
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
    guard case .success(.fun(let carEvaled)) = headResult else {
      switch headResult {
      case .failure(let evalError): return .failure(evalError)
      default: return makeEvalError("\(car) is not a function (in pair \(expr))")
      }
    }
    let pairs = collectPairs(cdr)
    guard case .success(let args) = pairs else {
      return pairs.map { _ in .null }
    }
    return carEvaled(args, env)
  case .variable(let val, let context):
    if let expr = env.get(key: val) {
      return .success(expr)
    } else {
      let contextString =
        context.flatMap {
          $0.renderSourceContext().map { "\nContext is:\n============\n\($0)\n============" }
        } ?? ""
      return .failure(EvalError(message: "Variable not found: \(val)".appending(contextString)))
    }
  default:
    return .success(expr)
  }
}

public func evalWithEnv(_ exprs: [Expr], _ env: Env) -> Result<Expr, EvalError> {
  return unapply(exprs).flatMap { (head, tail) in
    return tail.reduce(
      eval(head, env),
      { res, expr in
        return res.flatMap { _ in eval(expr, env) }
      })
  }
}

public func eval(_ exprs: [Expr]) -> Result<Expr, EvalError> {
  let newEnv = Env([:], baseEnv: stdLib)
  return evalWithEnv(exprs, newEnv)
}
