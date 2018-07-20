func lex(input: String) -> [String] {
  let initialAcc: ([String], String?) = ([], nil)
  let (tokens, partialToken) = input.reduce(
  initialAcc, { tuple, char in
    let tokens = tuple.0
    let currentToken = tuple.1
    switch char {
    case " ":
      if currentToken != nil {
        return (tokens + [currentToken!], nil)
      }
      return (tokens, nil)
    case "(":
      return (tokens + (currentToken != nil ? [currentToken!, "("] : ["("]), nil)
    case ")":
      return (tokens + (currentToken != nil ? [currentToken!, ")"] : [")"]), nil)
    case _:
      return (tokens, (currentToken ??  "") + String(char))
    }
  }
  )
  let emptyList: [String] = []
  return tokens + (partialToken != nil ? [partialToken!] : emptyList)
}
