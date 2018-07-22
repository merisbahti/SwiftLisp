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
