import SwiftParsec

func pairToString(_ pair: (Expr, Expr), _ showPairs: Bool = true) -> String {
  let (car, cdr) = pair
  let cdrIsPair = {
    switch cdr {
    case .pair(_): true
    default: false
    }
  }()
  let separator = cdr == .null ? "" : cdrIsPair ? " " : " . "
  let beginning = showPairs ? "(" : ""
  let end = !cdrIsPair ? ")" : ""

  let showPairsNext = {
    switch cdr {
    case .pair(_): false
    default: true
    }
  }()
  let cdrString = {
    switch cdr {
    case .pair(let pair):
      pairToString(pair, showPairsNext)
    case .null: ""
    default: "\(cdr)"
    }
  }()
  return "\(beginning)\(car)\(separator)\(cdrString)\(end)"
}

extension Expr: CustomStringConvertible {
  public var description: String {
    switch self {
    case Expr.number(let nbr):
      let str = String(nbr)
      if str.hasSuffix(".0") {
        return String(str.dropLast(2))
      }
      return str
    case .pair(let pair):
      return pairToString(pair)
    case Expr.variable(let string, _):
      return string
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

func resultOperation<T, E: Error>(
  _ lhs: Result<T, E>, _ rhs: Result<T, E>, _ operation: ((T, T) -> T)
) -> Result<T, E> {
  lhs.flatMap { (lhsValue) -> Result<T, E> in
    rhs.map { (rhsValue) -> T in
      return operation(lhsValue, rhsValue)
    }
  }
}

func resultsArray<T, E>(_ xs: [Result<T, E>]) -> Result<[T], E> {
  let inital: Result<[T], E> = .success([])
  return xs.reduce(inital) { (acc, curr) in
    switch (acc, curr) {
    case (.success(let acc), .success(let curr)): .success(acc.appending(curr))
    case (.failure(_), _): acc
    case (_, .failure(_)): curr.map { _ in [] }
    }
  }
}

func quoted(_ expr: Expr) -> Expr {
  return Expr.pair((Expr.variable("quote"), .pair((expr, .null))))
}

func exprsToPairs(_ exprs: [Expr]) -> Expr {
  switch exprs.first {
  case .some(let expr): .pair((expr, exprsToPairs(Array(exprs.dropFirst()))))
  default: .null
  }
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

public struct SourceContext {
  let sourcePosition: SourcePosition
  let input: String
  let length: Int

  func renderSourceContext()
    -> String?
  {
    let lines = input.split(separator: "\n", omittingEmptySubsequences: false)
    let before = lines[safe: sourcePosition.line - 2].map { ("\($0)") }
    let context = lines[safe: sourcePosition.line - 1].map { ("\($0)") }
    let highlighted =
      (0...(sourcePosition.column - 2)).map { _ in " " }.joined(separator: "")
      + ((0...length - 1).map { _ in "^" }).joined(separator: "")
    let after = lines[safe: sourcePosition.line].map { String($0) }

    if case .none = context {
      return .none
    }

    return [before, context, .some(highlighted), after].compactMap { $0 }.joined(separator: "\n")
  }

}

private func parseProgram(input: String) throws -> [Expr] {
  let newline =
    StringParser.character("\n")
  let semi = StringParser.character(";")
  let comment =
    (semi
    *> StringParser.anyCharacter.manyTill(newline)).map { _ in " " }

  let whitespace = StringParser.sourcePosition.flatMap { _ in
    StringParser.oneOf("  \n\r").map { _ in " " }
  }
  let skip = (comment <|> whitespace).many

  let oparen = StringParser.character("(")
  let cparen = StringParser.character(")")
  let quote = StringParser.character("'")

  let atomChars = "abcdefghijklmnopqrstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ+-/*?<>=0123456789.%"
  let atom = StringParser.sourcePosition.flatMap { sourcePos in

    { stringOrNumber in
      if let int = Float64(stringOrNumber) {
        return Expr.number(int)
      }
      return Expr.variable(
        stringOrNumber,
        SourceContext(sourcePosition: sourcePos, input: input, length: stringOrNumber.count))

    }
      <^> StringParser.oneOf(atomChars).many1.stringValue

  }
  let string =
    StringParser.sourcePosition.flatMap { sourcePos in
      { stringValue in
        let expr = Expr.string(stringValue)
        return expr
      }

        <^> (StringParser.oneOf("\"").stringValue *> StringParser.noneOf("\"").many.stringValue
          <* StringParser.oneOf("\"").stringValue)
    }

  let exprParser = GenericParser.recursive { (exprParser: GenericParser<String, (), Expr>) in
    let parseList: GenericParser<String, (), Expr>! =
      (exprsToPairs <^> (oparen *> exprParser.many <* cparen))
    let parseQuoted: GenericParser<String, (), Expr>! = (quoted <^> (quote *> exprParser))
    return skip *> (atom <|> parseList <|> string <|> parseQuoted) <* skip
  }

  let parsed = try exprParser.many1.run(sourceName: "", input: input)
  return (parsed)
}

public func read(input: String) -> Result<[Expr], EvalError> {
  do {
    let res = try parseProgram(input: input)
    return .success(res)
  } catch let parseError as ParseError {
    return .failure(EvalError(message: "parse error at:" + String(describing: parseError)))
  } catch let error {
    return .failure(EvalError(message: (String(describing: error))))
  }
}
