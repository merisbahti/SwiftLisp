extension Expr: CustomStringConvertible {
  public var description: String {
    switch self {
    case Expr.number(let nbr):
      return String(nbr)
    case Expr.variable(let string):
      return string
    case Expr.list(let exprs):
      return "(\(exprs.map({$0.description}).joined(separator: " ")))"
    case Expr.fun(_):
      return "function"
    case Expr.null:
      return "null"
    case Expr.bool(let bool):
      return "\(bool)"
    }
  }
}

func read(input: [String]) -> [Expr] {
  let result = read2(input: input)
  return result.0
}

func read2(input: [String]) -> ([Expr], [String]) {
  let head = input.first
  let tail = Array(input.dropFirst())
  switch head {
  case "(":
    let newresult = read2(input: tail)
    let newResultTail = read2(input: newresult.1)
    return ([Expr.list(newresult.0)] + newResultTail.0, newResultTail.1)
  case ")":
    return ([], tail)
  case let str where str != nil:
    let newresult = read2(input: tail)
    if let int = Int(str!) {
      return ([Expr.number(int)] + newresult.0, newresult.1)
    } else {
      return ([Expr.variable(str!)] + newresult.0, newresult.1)
    }
  default:
    return ([], [])
  }
}
