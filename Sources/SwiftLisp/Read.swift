enum Expr {
  case number(Int)
  case list([Expr])
  case variable(String)
}
extension Expr: CustomStringConvertible {
  var description: String {
    switch self {
    case Expr.number(let nbr):
      return String(nbr)
    case Expr.variable(let string):
      return string
    case Expr.list(let exprs):
      return "(\(exprs.reduce("", { "\($0) \($1)" })))"
    }
  }
}

func read(input: [String]) -> [Expr] {
  let head = input.first
  let tail = Array(input.dropFirst())
  switch head {
  case "(":
    return [Expr.list(read(input: tail))]
  case ")":
    return []
  case let str where str != nil:
    if let int = Int(str!) {
      return [Expr.number(int)] + read(input: tail)
    } else {
      return [Expr.variable(str!)] + read(input: tail)
    }
  default:
    return []
  }
}
