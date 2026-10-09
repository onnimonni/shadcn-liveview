import ts from "typescript"
import { toSnakeCase } from "./names"

export interface CvaSpec {
  baseClasses: string
  variants?: Record<string, Record<string, string>>
  defaultVariants?: Record<string, string>
}

function parseVariantOptions(node: ts.Expression, sf: ts.SourceFile): Record<string, string> {
  const options: Record<string, string> = {}
  if (!ts.isObjectLiteralExpression(node)) return options
  for (const option of node.properties) {
    if (!ts.isPropertyAssignment(option)) continue
    if (!ts.isStringLiteral(option.initializer) && !ts.isNoSubstitutionTemplateLiteral(option.initializer)) continue
    const key = option.name.getText(sf).replace(/^["'`]|["'`]$/g, "")
    options[key] = option.initializer.text.replace(/\s+/g, " ").trim()
  }
  return options
}

function parseVariants(node: ts.ObjectLiteralExpression, sf: ts.SourceFile): Record<string, Record<string, string>> {
  const variants: Record<string, Record<string, string>> = {}
  for (const property of node.properties) {
    if (!ts.isPropertyAssignment(property) || !ts.isIdentifier(property.name)) continue
    variants[property.name.text] = parseVariantOptions(property.initializer, sf)
  }
  return variants
}

function parseDefaults(node: ts.ObjectLiteralExpression): Record<string, string> {
  const defaults: Record<string, string> = {}
  for (const property of node.properties) {
    if (!ts.isPropertyAssignment(property) || !ts.isIdentifier(property.name)) continue
    if (ts.isStringLiteral(property.initializer)) defaults[property.name.text] = property.initializer.text
  }
  return defaults
}

function parseCvaCall(call: ts.CallExpression, sf: ts.SourceFile): CvaSpec {
  const base = call.arguments[0]
  const spec: CvaSpec = {
    baseClasses: base && (ts.isStringLiteral(base) || ts.isNoSubstitutionTemplateLiteral(base))
      ? base.text.replace(/\s+/g, " ").trim()
      : "",
    variants: undefined,
    defaultVariants: undefined,
  }
  const options = call.arguments[1]
  if (!options || !ts.isObjectLiteralExpression(options)) return spec
  for (const property of options.properties) {
    if (!ts.isPropertyAssignment(property) || !ts.isIdentifier(property.name)) continue
    if (!ts.isObjectLiteralExpression(property.initializer)) continue
    if (property.name.text === "variants") spec.variants = parseVariants(property.initializer, sf)
    if (property.name.text === "defaultVariants") spec.defaultVariants = parseDefaults(property.initializer)
  }
  return spec
}

export function collectCvaSpecs(sf: ts.SourceFile): Record<string, CvaSpec> {
  const specs: Record<string, CvaSpec> = {}
  for (const statement of sf.statements) {
    if (!ts.isVariableStatement(statement)) continue
    for (const declaration of statement.declarationList.declarations) {
      if (!ts.isIdentifier(declaration.name) || !declaration.initializer) continue
      if (!ts.isCallExpression(declaration.initializer)) continue
      if (declaration.initializer.expression.getText(sf) !== "cva") continue
      const name = toSnakeCase(declaration.name.text.replace(/Variants$/, ""))
      specs[name] = parseCvaCall(declaration.initializer, sf)
    }
  }
  return specs
}
