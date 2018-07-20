enum Result {
  case value(Expr, Env)
  case error(String)
}
enum Expr {
  case number(Int)
  case list([Expr])
  case variable(String)
  case fun(([Expr], Env) -> Result)
}
func operate(res1: Result, res2: Result, opfun: (Expr, Expr) -> Result) -> Result {
  return map(
    res: res1,
    fun: { expr1, _ in
      map(
        res: res2,
        fun: { expr2, _ in
          return opfun(expr1, expr2)
        }
        )
    })
}
func map(res: Result, fun: (Expr, Env) -> Result) -> Result {
  switch res {
  case .value(let expr, let env):
    return fun(expr, env)
  case let abc:
    return abc
  }
}

typealias Env = [String: Expr]

let stdLib: Env = [
"+": Expr.fun({ (exprs: [Expr], env: Env) in
  return exprs.reduce(Result.value(Expr.number(0), env), { acc, expr in
    return operate(res1: acc, res2: eval(expr: expr, env: env), opfun: { expr1, expr2 in
      switch (expr1, expr2) {
      case (Expr.number(let num1), Expr.number(let num2)):
        return Result.value(Expr.number(num1 + num2), env)
      case _:
        return Result.error("No number in + operand")
      }
                   })
  })
}),
"def": Expr.fun({ (exprs: [Expr], env: Env) in
  let head = exprs.first
  let expr = exprs.dropFirst().first
  if let symbol = head {
    switch symbol {
    case Expr.variable(let variableName):
      return map(res: eval(expr: expr!, env: env), fun: { newExpr, newEnv in
        return .value(
          newExpr,
          env.merging([variableName: newExpr]) { newEnv, _ in newEnv })
      })
    case _:
      return .error("First argument to def must be symbol, found: \(symbol)")
    }
  }
  return .error("No symbol as first argument to def.")
                })
]
func eval(expr: Expr, env: Env) -> Result {
  switch expr {
  case .list(let tokenList):
    let tail = Array(tokenList.dropFirst())
    if let head = tokenList.first {
      let mapFunc: (Expr, Env) -> Result = { expr, env in
        switch expr {
        case .fun(let fun):
          return fun(tail, env)
        case let other:
          return .error("Head of list is not a function, \(head) in list \(expr) type: \(other)")
        }
      }
      return map(res: eval(expr: head, env: env), fun: mapFunc)
    } else {
      return .error("Cannot evaluate empty list")
    }
  case .number(let int):
    return .value(.number(int), env)
  case .variable(let val):
    if let expr = env[val] {
      return .value(expr, env)
    } else {
      return .error("Variable not found: \(val), env: \(env)")
    }
  case .fun:
    return .error("Cannot eval function. Maybe return self here?")
  }
}
func eval(exprs: [Expr]) -> Result {
  if let head = exprs.first {
    return exprs.reduce(
      eval(expr: head, env: stdLib), { res, expr in
        return map(res: res, fun: { _, newEnv in return eval(expr: expr, env: newEnv) })
      }
    )
  } else {
    return .error("Empty expression?")
  }
}
