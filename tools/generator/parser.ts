import ts from "typescript"
import type { ComponentFunctionSpec, ComponentSpec } from "../generate"
import { collectCvaSpecs } from "./cva"
import { applyComponentMetadata } from "./component-metadata"
import { resolveHtmlTag } from "./html-tags"
import { inspectComponentSurface } from "./jsx"
import { toPascalCase, toSnakeCase } from "./names"

function collectDeclarations(sf: ts.SourceFile): { node: ts.Node; name: string }[] {
  const declarations: { node: ts.Node; name: string }[] = []
  for (const statement of sf.statements) {
    if (ts.isFunctionDeclaration(statement) && statement.name) {
      declarations.push({ node: statement, name: statement.name.text })
      continue
    }
    if (!ts.isVariableStatement(statement)) continue
    for (const declaration of statement.declarationList.declarations) {
      if (!ts.isIdentifier(declaration.name) || !declaration.initializer) continue
      const name = declaration.name.text
      if (!name.endsWith("Variants")) declarations.push({ node: declaration.initializer, name })
    }
  }
  return declarations
}

export function parseComponent(fileName: string, code: string): ComponentSpec {
  const sf = ts.createSourceFile(`${fileName}.tsx`, code, ts.ScriptTarget.Latest, true)
  const cvaByFunction = collectCvaSpecs(sf)
  const functions: ComponentFunctionSpec[] = []
  const seenNames = new Set<string>()
  for (const { node, name } of collectDeclarations(sf)) {
    const fnSnakeName = toSnakeCase(name)
    if (seenNames.has(fnSnakeName)) continue
    seenNames.add(fnSnakeName)
    const isPrimary = name.toLowerCase() === fileName.replace(/-/g, "").toLowerCase()
    // A family's first CVA may belong to a child (e.g. EmptyMedia), not its root.
    const matchedCva = cvaByFunction[fnSnakeName] || (isPrimary ? cvaByFunction[toSnakeCase(fileName)] : undefined)
    const surface = inspectComponentSurface(node, fnSnakeName, matchedCva?.baseClasses || "", sf)
    const metadata = applyComponentMetadata(
      fnSnakeName, resolveHtmlTag(name, surface.tag), surface.hasDataSize,
      surface.hasDataVariant, matchedCva, surface.staticAttrs,
    )
    functions.push({
      name: fnSnakeName,
      tag: metadata.tag,
      slotName: surface.slotName,
      baseClasses: surface.baseClasses,
      variants: matchedCva?.variants,
      defaultVariants: matchedCva?.defaultVariants,
      attrs: metadata.attrs,
      hasDataVariant: surface.hasDataVariant,
      hasDataSize: surface.hasDataSize,
      staticAttrs: surface.staticAttrs,
    })
  }
  // CVA metadata alone describes styles, not a renderable component.
  if (functions.length === 0) throw new Error(`No component declarations found in "${fileName}.tsx"`)
  return { name: fileName, moduleName: toPascalCase(fileName), functions }
}
