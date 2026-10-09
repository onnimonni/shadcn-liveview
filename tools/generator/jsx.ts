import ts from "typescript"

interface ComponentSurface {
  slotName: string
  baseClasses: string
  tag: string
  hasDataVariant: boolean
  hasDataSize: boolean
  staticAttrs: string[]
}

type Opening = ts.JsxOpeningElement | ts.JsxSelfClosingElement

function findComponentOpening(node: ts.Node, slot: string, sf: ts.SourceFile): Opening | undefined {
  const openings: Opening[] = []
  function collectJsx(child: ts.Node) {
    if (ts.isJsxElement(child)) openings.push(child.openingElement)
    else if (ts.isJsxSelfClosingElement(child)) openings.push(child)
    ts.forEachChild(child, collectJsx)
  }
  collectJsx(node)
  const hasAttribute = (opening: Opening, name: string) =>
    opening.attributes.properties.some(prop => ts.isJsxAttribute(prop) && prop.name.getText(sf) === name)
  return openings.find(candidate => candidate.attributes.properties.some(prop =>
    ts.isJsxAttribute(prop) && prop.name.getText(sf) === "data-slot" &&
    prop.initializer && ts.isStringLiteral(prop.initializer) && prop.initializer.text === slot))
    ?? openings.find(candidate => hasAttribute(candidate, "className"))
    ?? openings.find(candidate => hasAttribute(candidate, "data-slot") || hasAttribute(candidate, "role"))
}

function literalClasses(initializer: ts.JsxAttributeValue): string | undefined {
  const expression = ts.isJsxExpression(initializer) ? initializer.expression : initializer
  if (!expression) return undefined
  if (ts.isStringLiteral(expression) || ts.isNoSubstitutionTemplateLiteral(expression)) {
    return expression.text.replace(/\s+/g, " ").trim()
  }
  if (!ts.isCallExpression(expression)) return undefined
  const first = expression.arguments[0]
  if (!first || (!ts.isStringLiteral(first) && !ts.isNoSubstitutionTemplateLiteral(first))) return undefined
  return expression.arguments
    .filter((argument): argument is ts.StringLiteral | ts.NoSubstitutionTemplateLiteral =>
      ts.isStringLiteral(argument) || ts.isNoSubstitutionTemplateLiteral(argument))
    .map(argument => argument.text).join(" ").replace(/\s+/g, " ").trim()
}

export function inspectComponentSurface(node: ts.Node, name: string, baseClasses: string, sf: ts.SourceFile): ComponentSurface {
  const surface: ComponentSurface = {
    slotName: name.replace(/_/g, "-"),
    baseClasses,
    tag: "div",
    hasDataVariant: false,
    hasDataSize: false,
    staticAttrs: [],
  }
  const opening = findComponentOpening(node, surface.slotName, sf)
  if (!opening) return surface
  surface.tag = opening.tagName.getText(sf)
  for (const property of opening.attributes.properties) {
    if (!ts.isJsxAttribute(property)) continue
    const name = property.name.getText(sf)
    if (name === "data-variant") surface.hasDataVariant = true
    if (name === "data-size") surface.hasDataSize = true
    const initializer = property.initializer
    if (!initializer) continue
    if (name === "data-slot" && ts.isStringLiteral(initializer)) surface.slotName = initializer.text
    if (name === "role" && ts.isStringLiteral(initializer)) surface.staticAttrs.push(`role="${initializer.text}"`)
    if (name === "className") surface.baseClasses = literalClasses(initializer) ?? surface.baseClasses
  }
  return surface
}
