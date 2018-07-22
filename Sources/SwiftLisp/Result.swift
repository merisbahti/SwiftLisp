enum Result<T> {
  case value(T)
  case error(String)
}
func operate(res1: EvalResult, res2: EvalResult, opfun: (Expr, Expr) -> EvalResult) -> EvalResult {
  return map(
    res1, { expr1 in
      map(
        res2, { expr2 in
          return opfun(expr1.0, expr2.0)
        }
        )
    })
}
func map<A, B>(_ res: Result<A>, _ fun: (A) -> Result<B>) -> Result<B> {
  switch res {
  case .value(let val):
    return fun(val)
  case .error(let err):
    return Result<B>.error(err)
  }
}

