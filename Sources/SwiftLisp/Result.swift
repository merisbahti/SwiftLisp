enum Result<T> {
  case value(T)
  case error(String)
}
func operate(res1: EvalResult, res2: EvalResult, opfun: (Expr, Expr) -> EvalResult) -> EvalResult {
  return res1.flatMap { expr1 in
    return res2.flatMap { expr2 in
      return opfun(expr1.0, expr2.0)
    }
  }
}
extension Result where T: Equatable {
    static func == (lhs: Result<T>, rhs: Result<T>) -> Bool {
      switch (lhs, rhs) {
      case (.value(let lhsVal), .value(let rhsVal)):
        return lhsVal == rhsVal
      case (.error(let err1), .error(let err2)):
        return err1 == err2
      default:
        return false
      }
    }
}
extension Result {
  func flatMap<B>(_ fun: (T) -> Result<B>) -> Result<B> {
    switch self {
    case .value(let val):
      return fun(val)
    case .error(let err):
      return Result<B>.error(err)
    }
  }
}
extension Result {
  func orElse(_ fun: (String) -> Result<T>) -> Result<T> {
    switch self {
    case .error(let err):
      return fun(err)
    default:
      return self
    }
  }
}
extension Result {
  func forEach(_ fun: (T) -> Void) {
    switch self {
    case .value(let val):
      fun(val)
    case .error:
      break
    }
  }
}
extension Result {
  func flapFlap(_ err: String) -> Result<T> {
    switch self {
    case .error:
      return Result<T>.error(err)
    default:
      return self
    }
  }
}
