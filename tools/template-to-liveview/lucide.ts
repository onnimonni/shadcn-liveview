import fs from "node:fs"
import path from "node:path"
import { parseExpression } from "@babel/parser"
import type * as t from "@babel/types"

// Inline-SVG fallback for Lucide icons that icon/1 does not ship, read from a lucide-react
// package when one is available (the template's own node_modules, or --lucide <dir>).

export interface LucideIcons {
  svg(component: string): string | undefined
}

export function findLucide(explicit?: string, from: string[] = []): LucideIcons | undefined {
  const candidates = explicit ? [explicit] : from.flatMap(start => {
    const dirs: string[] = []
    let dir = path.resolve(start)
    for (let depth = 0; depth < 6; depth++) {
      dirs.push(path.join(dir, "node_modules", "lucide-react"), path.join(dir, "assets", "node_modules", "lucide-react"))
      const parent = path.dirname(dir)
      if (parent === dir) break
      dir = parent
    }
    return dirs
  })
  const root = candidates.find(candidate => fs.existsSync(path.join(candidate, "dist", "esm", "lucide-react.mjs")))
  if (!root) return undefined
  const index = fs.readFileSync(path.join(root, "dist", "esm", "lucide-react.mjs"), "utf8")
  const files = new Map<string, string>()
  for (const match of index.matchAll(/export \{([^}]*)\} from '\.\/icons\/([\w-]+)\.mjs'/g)) {
    for (const alias of match[1].matchAll(/as (\w+)/g)) files.set(alias[1], match[2])
  }
  const cache = new Map<string, string | undefined>()
  return {
    svg(component: string) {
      const name = component.replace(/^Lucide/, "")
      if (cache.has(name)) return cache.get(name)
      const file = files.get(name) ?? files.get(`${name}Icon`) ?? files.get(name.replace(/Icon$/, ""))
      let svg: string | undefined
      if (file) {
        const source = fs.readFileSync(path.join(root, "dist", "esm", "icons", `${file}.mjs`), "utf8")
        const data = source.match(/const __iconData = (\{[\s\S]*?\n\});/)?.[1]
        const object = data ? parseExpression(data) : undefined
        const node = object?.type === "ObjectExpression" ? object.properties.find(property => property.type === "ObjectProperty" && property.key.type === "Identifier" && property.key.name === "node") : undefined
        if (node?.type === "ObjectProperty" && node.value.type === "ArrayExpression") svg = renderSvg(file, node.value)
      }
      cache.set(name, svg)
      return svg
    },
  }
}

function renderSvg(name: string, node: t.ArrayExpression): string {
  const children = node.elements.map(element => {
    if (element?.type !== "ArrayExpression") return ""
    const [tag, attrs] = element.elements
    if (tag?.type !== "StringLiteral" || attrs?.type !== "ObjectExpression") return ""
    const parts = attrs.properties.flatMap(property => {
      if (property.type !== "ObjectProperty" || property.key.type !== "Identifier" || property.key.name === "key") return []
      const value = property.value.type === "StringLiteral" ? property.value.value : property.value.type === "NumericLiteral" ? String(property.value.value) : ""
      return [`${property.key.name.replace(/([A-Z])/g, "-$1").toLowerCase()}="${value}"`]
    })
    return `<${tag.value} ${parts.join(" ")} />`
  }).join("")
  return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class={["lucide lucide-${name}", @class]} aria-hidden="true" {@rest}>${children}</svg>`
}
