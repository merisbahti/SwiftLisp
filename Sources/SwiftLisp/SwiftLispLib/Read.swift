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

private func NumberOrVariable (val: String) -> Expr {
  if let int = Int(val) {
    return .number(int)
  } else {
    return .variable(val)
  }
}

private func parseExpr () -> GenericParser<String, (), Expr> {
  let skip = StringParser.oneOf("  \n\r").many
  let oparen = StringParser.character("(")
  let cparen = StringParser.character(")")

  let atomChars = "abcdefghijklmnopqrstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ+-/*?<>=0123456789"
  let atom = NumberOrVariable <^> StringParser.oneOf(atomChars).many1.stringValue

  let string = Expr.string <^> (
    StringParser.oneOf("\"").stringValue *>
    StringParser.noneOf("\"").many.stringValue <*
    StringParser.oneOf("\"").stringValue
  )

  var parseList: GenericParser<String, (), Expr>!
  let parseExpr = GenericParser.recursive { (exprParser: GenericParser<String, (), Expr>) in
    parseList = Expr.list <^> (oparen *> exprParser.many <* cparen)
    return skip *> (atom <|> parseList <|> string) <* skip
  }
  return parseExpr
}

private let parseProgram = parseExpr().many1

func read (input: String) -> Result<[Expr]> {
  let parser = parseProgram
  do {
    let exprs = try parser.run(sourceName: "", input: input)
    return Result.value(exprs)
  } catch let parseError as ParseError {
    return .error("parse error at:" + String(describing: parseError))
  } catch let error {
    return .error(String(describing: error))
  }
}
