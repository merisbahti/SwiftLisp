import SwiftParsec

func lispParser() -> GenericParser<String, (), [Expr]> {
  // let skip = StringParser.character(" ")
  let firstIdentifierChar = "abcdefghijklmnopqrstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ-+/*?<>=0123456789"
  let identifierParser = StringParser.oneOf(firstIdentifierChar).many1
  let json = LanguageDefinition<()>.json
  let lexer = GenericTokenParser(languageDefinition: json)
  let oparen = StringParser.character("(")
  let cparen = StringParser.character(")")
  let identifier = Expr.variable <^> identifierParser.stringValue
  let number = Expr.number <^> (lexer.integer.attempt)
  let atom = number <|> identifier
  let inparen = Expr.list <^> (oparen *> atom.many <* cparen)
  return inparen.many
}

let lispData = """
(ab 12 456
  12 45
  )
"""

func doThing() {
  print(lispParser().test(input: lispData))
}
