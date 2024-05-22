import SwiftParsec

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
    case .string(let str):
      return "\"\(str)\""
    }
  }
}

private func numberOrVariable(val: String) -> Expr {
  if let int = Int(val) {
    return .number(int)
  } else {
    return .variable(val)
  }
}

func quoted(_ expr: Expr) -> Expr { return Expr.list([Expr.variable("quote"), expr]) }

private func parseExpr() -> GenericParser<String, (), Expr> {
  let skip = StringParser.oneOf("  \n\r").many
  let oparen = StringParser.character("(")
  let cparen = StringParser.character(")")
  let quote = StringParser.character("'")

  let atomChars = "abcdefghijklmnopqrstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ+-/*?<>=0123456789"
  let atom = numberOrVariable <^> StringParser.oneOf(atomChars).many1.stringValue

  let string =
    Expr.string
    <^> (StringParser.oneOf("\"").stringValue *> StringParser.noneOf("\"").many.stringValue
      <* StringParser.oneOf("\"").stringValue)

  let parseExpr = GenericParser.recursive { (parseExpr: GenericParser<String, (), Expr>) in
    let parseList: GenericParser<String, (), Expr>! =
      (Expr.list <^> (oparen *> parseExpr.many <* cparen))
    let parseQuoted: GenericParser<String, (), Expr>! = (quoted <^> (quote *> parseExpr))
    return skip *> (atom <|> parseList <|> string <|> parseQuoted) <* skip
  }
  return parseExpr
}

private let parseProgram = parseExpr().many1

func read(input: String) -> Result<[Expr], EvalError> {
  let parser = parseProgram
  do {
    let exprs = try parser.run(sourceName: "", input: input)
    return .success(exprs)
  } catch let parseError as ParseError {
    return .failure(EvalError(message: "parse error at:" + String(describing: parseError)))
  } catch let error {
    return .failure(EvalError(message: (String(describing: error))))
  }
}
