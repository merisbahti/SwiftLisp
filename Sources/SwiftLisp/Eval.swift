enum Result {
  case value(Expr)
  case error(String)
}
let stdLib = [
  "+": { (exprs: [Expr]) in
  }
]
func eval(expr: Expr) -> Result {
  switch expr {
  case .list(let tokenList):
    let head = tokenList.first
    let tail = Array(tokenList.dropFirst())
    return .value(Expr.variable("Hello"))
  case .number(let int):
    return .value(.number(int))
  case .variable(let val):
    return .error("Variables aren't implemented")
  }
}
