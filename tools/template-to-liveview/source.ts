import fs from "node:fs"
import path from "node:path"
import { parse } from "@babel/parser"
import type * as t from "@babel/types"

export interface ImportRef {
  source: string
  imported: string // "default", "*" or the exported name
}

export type ImportKind =
  | { kind: "ui"; family: string }
  | { kind: "icon-placeholder" }
  | { kind: "lucide" }
  | { kind: "icon-other"; source: string }
  | { kind: "cn" }
  | { kind: "react" }
  | { kind: "next-link" }
  | { kind: "next-image" }
  | { kind: "sonner" }
  | { kind: "local"; file: string }
  | { kind: "unknown"; source: string }

export interface ComponentDecl {
  name: string
  file: string
  node: t.FunctionDeclaration | t.ArrowFunctionExpression | t.FunctionExpression
  exported: boolean
  isDefault: boolean
}

export interface ParsedFile {
  file: string
  code: string
  ast: t.File
  imports: Map<string, ImportRef>
  components: Map<string, ComponentDecl>
  consts: Map<string, t.Expression>
  defaultExport?: string
}

/** Source files of one template: a block directory, a single file or a registry item. */
export interface SourceSet {
  entry: string
  files: Map<string, string>
  /** Directories searched (with their ancestors) when resolving `@/...` imports from disk. */
  roots: string[]
  label: string
}

export function parseSource(file: string, code: string): ParsedFile {
  const ast = parse(code, { sourceType: "module", plugins: ["jsx", "typescript"], errorRecovery: true })
  const imports = new Map<string, ImportRef>()
  const components = new Map<string, ComponentDecl>()
  const consts = new Map<string, t.Expression>()
  let defaultExport: string | undefined
  const exportedNames = new Set<string>()

  const addFunction = (name: string, node: ComponentDecl["node"], exported: boolean, isDefault: boolean) => {
    if (/^[A-Z]/.test(name)) components.set(name, { name, file, node, exported, isDefault })
  }
  const addVariable = (declaration: t.VariableDeclaration, exported: boolean) => {
    for (const declarator of declaration.declarations) {
      if (declarator.id.type !== "Identifier" || !declarator.init) continue
      const name = declarator.id.name
      let init: t.Expression = declarator.init
      while (init.type === "TSAsExpression" || init.type === "TSSatisfiesExpression") init = init.expression
      if ((init.type === "ArrowFunctionExpression" || init.type === "FunctionExpression") && /^[A-Z]/.test(name)) {
        addFunction(name, init, exported, false)
      } else {
        consts.set(name, init)
      }
    }
  }

  for (const statement of ast.program.body) {
    if (statement.type === "ImportDeclaration") {
      if (statement.importKind === "type") continue
      for (const specifier of statement.specifiers) {
        if (specifier.type === "ImportDefaultSpecifier") imports.set(specifier.local.name, { source: statement.source.value, imported: "default" })
        else if (specifier.type === "ImportNamespaceSpecifier") imports.set(specifier.local.name, { source: statement.source.value, imported: "*" })
        else if (specifier.importKind !== "type") {
          const imported = specifier.imported.type === "Identifier" ? specifier.imported.name : specifier.imported.value
          imports.set(specifier.local.name, { source: statement.source.value, imported })
        }
      }
    } else if (statement.type === "FunctionDeclaration" && statement.id) {
      addFunction(statement.id.name, statement, false, false)
    } else if (statement.type === "VariableDeclaration") {
      addVariable(statement, false)
    } else if (statement.type === "ExportNamedDeclaration") {
      const declaration = statement.declaration
      if (declaration?.type === "FunctionDeclaration" && declaration.id) addFunction(declaration.id.name, declaration, true, false)
      else if (declaration?.type === "VariableDeclaration") addVariable(declaration, true)
      for (const specifier of statement.specifiers) {
        if (specifier.type === "ExportSpecifier") exportedNames.add(specifier.local.name)
      }
    } else if (statement.type === "ExportDefaultDeclaration") {
      const declaration = statement.declaration
      if (declaration.type === "FunctionDeclaration") {
        const name = declaration.id?.name ?? "Page"
        addFunction(name, declaration, true, true)
        defaultExport = name
      } else if (declaration.type === "Identifier") {
        defaultExport = declaration.name
      } else if (declaration.type === "ArrowFunctionExpression" || declaration.type === "FunctionExpression") {
        addFunction("Page", declaration, true, true)
        defaultExport = "Page"
      }
    }
  }
  for (const name of exportedNames) {
    const component = components.get(name)
    if (component) component.exported = true
  }
  if (defaultExport) {
    const component = components.get(defaultExport)
    if (component) Object.assign(component, { exported: true, isDefault: true })
  }
  return { file, code, ast, imports, components, consts, defaultExport }
}

const uiImport = /(?:^|\/)ui\/([\w-]+)$/
const iconLibraries = /^(@tabler\/icons-react|@hugeicons\/|@phosphor-icons\/|@remixicon\/react|@radix-ui\/react-icons|react-icons)/

export function classifyImport(set: SourceSet, fromFile: string, source: string, imported: string): ImportKind {
  const ui = source.match(uiImport)
  if (ui) return { kind: "ui", family: ui[1].replace(/-/g, "_") }
  if (imported === "IconPlaceholder" || /icon-placeholder$/.test(source)) return { kind: "icon-placeholder" }
  if (source === "lucide-react" || source.startsWith("lucide-react/")) return { kind: "lucide" }
  if (iconLibraries.test(source)) return { kind: "icon-other", source }
  if (source === "cn" || source === "clsx" || source === "tailwind-merge" || /\/lib\/utils$/.test(source)) return { kind: "cn" }
  if (source === "react") return { kind: "react" }
  if (source === "next/link") return { kind: "next-link" }
  if (source === "next/image") return { kind: "next-image" }
  if (source === "sonner") return { kind: "sonner" }
  const local = resolveLocal(set, fromFile, source)
  if (local) return { kind: "local", file: local }
  return { kind: "unknown", source }
}

const extensions = [".tsx", ".ts", ".jsx", ".js", "/index.tsx", "/index.ts"]

function existing(set: SourceSet, candidate: string): string | undefined {
  for (const extension of ["", ...extensions]) {
    const file = path.normalize(candidate + extension)
    if (set.files.has(file)) return file
    if (/\.(tsx|ts|jsx|js)$/.test(file) && fs.existsSync(file) && fs.statSync(file).isFile()) {
      set.files.set(file, fs.readFileSync(file, "utf8"))
      return file
    }
  }
  return undefined
}

/**
 * Resolves relative imports and alias imports (`@/registry/<style>/blocks/<block>/components/x`,
 * `@/components/x`) by their path tail, looking in the template's own files first and then in the
 * directories (and ancestors) of the input.
 */
function resolveLocal(set: SourceSet, fromFile: string, source: string): string | undefined {
  if (source.startsWith(".")) return existing(set, path.resolve(path.dirname(fromFile), source))
  if (!source.startsWith("@/") && !source.startsWith("~/")) return undefined
  const segments = source.slice(2).split("/")
  // Try ever shorter tails: blocks/login-03/components/login-form → components/login-form → login-form.
  for (let start = 0; start < segments.length; start++) {
    const tail = segments.slice(start).join("/")
    for (const file of set.files.keys()) {
      const withoutExtension = file.replace(/\.(tsx|ts|jsx|js)$/, "")
      if (withoutExtension.endsWith(`/${tail}`) || withoutExtension === tail) return file
    }
  }
  for (const root of set.roots) {
    let dir = path.resolve(root)
    for (let depth = 0; depth < 4; depth++) {
      for (let start = 0; start < segments.length - 1; start++) {
        const found = existing(set, path.join(dir, ...segments.slice(start)))
        if (found) return found
      }
      const parent = path.dirname(dir)
      if (parent === dir) break
      dir = parent
    }
  }
  return undefined
}

/**
 * File of a static JSON import (`import data from "./data.json"`): a template file (registry item
 * or already loaded), the path relative to the importing file, or an `@/` alias resolved by its tail.
 */
export function resolveJson(set: SourceSet, fromFile: string, source: string): string | undefined {
  if (!source.endsWith(".json")) return undefined
  const load = (file: string): string | undefined => {
    if (set.files.has(file)) return file
    if (fs.existsSync(file) && fs.statSync(file).isFile()) {
      set.files.set(file, fs.readFileSync(file, "utf8"))
      return file
    }
    return undefined
  }
  if (source.startsWith(".")) return load(path.resolve(path.dirname(fromFile), source))
  if (!source.startsWith("@/") && !source.startsWith("~/")) return undefined
  const segments = source.slice(2).split("/")
  for (let start = 0; start < segments.length; start++) {
    const tail = segments.slice(start).join("/")
    for (const file of set.files.keys()) if (file.endsWith(`/${tail}`)) return file
  }
  for (const root of set.roots) {
    for (let start = 0; start < segments.length; start++) {
      const found = load(path.join(path.resolve(root), ...segments.slice(start)))
      if (found) return found
    }
  }
  return undefined
}

function sourceFilesIn(dir: string): string[] {
  const result: string[] = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) result.push(...sourceFilesIn(full))
    else if (/\.(tsx|jsx)$/.test(entry.name)) result.push(full)
  }
  return result.sort()
}

export function loadPath(input: string): SourceSet {
  const resolved = path.resolve(input)
  if (fs.statSync(resolved).isDirectory()) {
    const files = new Map(sourceFilesIn(resolved).map(file => [file, fs.readFileSync(file, "utf8")]))
    const entry = ["page.tsx", "index.tsx", "page.jsx", "index.jsx"].map(name => path.join(resolved, name)).find(file => files.has(file))
      ?? (files.size === 1 ? [...files.keys()][0] : undefined)
    if (!entry) throw new Error(`${input}: no page.tsx/index.tsx entry; pass the entry file instead of the directory.`)
    return { entry, files, roots: [resolved], label: path.basename(resolved) }
  }
  return {
    entry: resolved,
    files: new Map([[resolved, fs.readFileSync(resolved, "utf8")]]),
    roots: [path.dirname(resolved)],
    label: path.basename(resolved).replace(/\.(tsx|jsx)$/, ""),
  }
}

interface RegistryItem {
  name?: string
  files?: { path: string; content?: string; type?: string; target?: string }[]
}

/** A shadcn registry item (`https://ui.shadcn.com/r/styles/<style>/<name>.json` or its saved JSON). */
export function loadRegistryItem(json: string, label?: string): SourceSet {
  const item = JSON.parse(json) as RegistryItem
  const files = new Map<string, string>()
  let entry: string | undefined
  for (const file of item.files ?? []) {
    if (!file.content || !/\.(tsx|jsx|json)$/.test(file.path)) continue
    const name = path.resolve("/registry", file.path)
    files.set(name, file.content)
    if (!entry && /\.(tsx|jsx)$/.test(file.path) && (file.type === "registry:page" || /(?:^|\/)page\.tsx$/.test(file.path))) entry = name
  }
  entry ??= [...files.keys()].find(file => /\.(tsx|jsx)$/.test(file))
  if (!entry) throw new Error("Registry item has no TSX file content.")
  return { entry, files, roots: [], label: label ?? item.name ?? "registry-item" }
}

export function lineOf(node: t.Node | null | undefined): number {
  return node?.loc?.start.line ?? 0
}
