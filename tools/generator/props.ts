import ts from "typescript"

export interface PropEnum {
  values: string[]
  default?: string
}

function stringLiterals(type: ts.TypeNode): string[] | undefined {
  const members = ts.isUnionTypeNode(type) ? type.types : [type]
  const values: string[] = []
  for (const member of members) {
    // Any non-literal member (string, undefined, a reference) leaves the prop open.
    if (!ts.isLiteralTypeNode(member) || !ts.isStringLiteral(member.literal)) return undefined
    values.push(member.literal.text)
  }
  return values
}

function collectUnions(type: ts.TypeNode, enums: Record<string, PropEnum>): void {
  if (ts.isIntersectionTypeNode(type)) type.types.forEach(member => collectUnions(member, enums))
  else if (ts.isParenthesizedTypeNode(type)) collectUnions(type.type, enums)
  else if (ts.isTypeLiteralNode(type)) {
    for (const member of type.members) {
      if (!ts.isPropertySignature(member) || !member.type || !ts.isIdentifier(member.name)) continue
      const values = stringLiterals(member.type)
      if (values) enums[member.name.text] = { values }
    }
  }
}

// Closed string-literal props a component declares inline, with their destructured defaults.
export function collectPropEnums(node: ts.Node): Record<string, PropEnum> {
  if (!ts.isFunctionDeclaration(node) && !ts.isArrowFunction(node) && !ts.isFunctionExpression(node)) return {}
  const props = node.parameters[0]
  if (!props?.type) return {}
  const enums: Record<string, PropEnum> = {}
  collectUnions(props.type, enums)
  if (ts.isObjectBindingPattern(props.name)) {
    for (const element of props.name.elements) {
      if (!ts.isIdentifier(element.name) || !element.initializer || !ts.isStringLiteral(element.initializer)) continue
      const known = enums[element.name.text]
      if (known) known.default = element.initializer.text
    }
  }
  return enums
}
