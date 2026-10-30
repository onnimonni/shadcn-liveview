import type * as t from "@babel/types"
import { atomAccess, elixirString, kebab, normalizeMaps, printTerm, toSnakeCase, type Term } from "./elixir"
import { toPascalCase } from "../generator/names"
import { sendEventMethod } from "../converters/hook-events"
import {
  clickEvents, contextKey, familyRule, fieldControls, modalFamilies, popupFamilies, qualifiedFunctions, rules,
  transparentComponents, yieldingRoots,
} from "./families"
import { el, type HAttr, type HElement, type HNode, printNodes, quoteAttr } from "./heex"
import { type LucideIcons } from "./lucide"
import { acceptsAttr, type FnMeta, isGlobalAttr, lucideKebab, lucideName, type Metadata } from "./metadata"
import { classifyImport, type ComponentDecl, type ImportKind, lineOf, type ParsedFile, parseSource, resolveJson, type SourceSet } from "./source"
import {
  callsAny, columnArray, commonElement, findElement, findMember, parseColumns, propertyValue, staticText, type TableColumn, type TablePartKind,
  tableHooks, tableUses, tanstackSource, unwrapTs,
} from "./tanstack"

export interface Todo { file: string; line: number; reason: string; rule: string }
export interface Note { file: string; line: number; message: string }
/** Source that produced neither output nor a TODO comment (listed under "Source completeness"). */
export interface Skipped { file: string; line: number; endLine: number; kind: SkippedKind; message: string; rule: string }
export type SkippedKind = "component" | "column" | "render-prop" | "callback" | "markup" | "library"
/** Generated handle_event/3 clause that only echoes its params; it must be implemented by hand. */
export interface Placeholder { event: string; file: string; line: number }

export interface ConvertOptions {
  module: string
  /** `MyAppWeb` for `use MyAppWeb, :live_view`; derived from the module name when omitted. */
  web?: string
  mode?: "live" | "component"
  lucide?: LucideIcons
}

export interface ConvertResult {
  code: string
  todos: Todo[]
  notes: Note[]
  /** React component/element → LiveView function, with counts. */
  mapping: { react: string; liveview: string; count: number }[]
  components: string[]
  events: string[]
  assigns: string[]
  families: string[]
  /** Files whose components were (at least partly) converted; see `skipped` for what was not. */
  files: string[]
  skipped: Skipped[]
  placeholders: Placeholder[]
  /** The module tracks `@is_mobile` (connect params + the colocated `.Viewport` hook). */
  viewport: boolean
  /**
   * Root-relative static files the output references (`/placeholder.svg`, `/avatars/shadcn.jpg`): the app must
   * serve them. `url` is where the original lives when the template is a shadcn block (ui.shadcn.com serves them).
   */
  assets: { path: string; url?: string }[]
  entry: string
  label: string
  module: string
}

class Unsupported extends Error {}
/** Unsupported, and the element's children cannot be rendered on their own either. */
class Skip extends Unsupported {}

type Binding =
  | { b: "code"; code: string; item?: LoopItem; string?: boolean } // `string`: known to hold a string (formatter args)
  | { b: "state"; assign: string }
  | { b: "setter"; assign: string }
  | { b: "rest" }
  | { b: "children" }
  | { b: "const"; key: string }
  | { b: "local"; node: t.Expression; ctx: Ctx }
  | { b: "sidebar" }
  | { b: "icon"; code: string } // a lucide/icon component value (`icon: Icon`)
  | { b: "unknown"; reason: string }
  | { b: "table"; spec: TableSpec } // TanStack `useReactTable`/`useTable` instance converted to a DataTable
  | { b: "tableRow"; code: string } // TanStack `row` in a cell renderer (`row.original` is the row map)
  | { b: "cellValue"; code: string } // `getValue` destructured from a cell renderer's context
  | { b: "cellInfo"; row: string; value: string } // a cell renderer's whole context (`info.getValue()`, `info.row`)

/** A TanStack table converted to `ShadcnLiveview.DataTable` (state assign, rows assign, parts). */
interface TableSpec {
  id: string
  assign: string
  rowsAssign: string
  unit: Unit
  line: number
  columns: { column: TableColumn; kind: "data" | "select" | "actions" | "drag" }[]
  /** Resolves names in the file that defines the columns (it may differ from the component's). */
  columnsCtx: Ctx
  data?: t.Expression
  /** Bindings where the table was declared (`data` resolves here). */
  scope: Map<string, Binding>
  rowKey: string
  newOptions: string
}

interface Ctx {
  unit: Unit
  scope: Map<string, Binding>
  contexts: Map<string, string>
  loopIndexes: string[]
  form?: string // assign holding the form
  replace?: Map<t.Node, HNode[]> // JSX parts already converted elsewhere (family triggers/contents)
  /** `@item_key` inside a component rendered once per loop item / table row: suffix of its generated ids. */
  idKey?: string
}

interface Need { attr: string; kind: "assign" | "context" }

/** `team` in `teams.map((team, index) => ...)`: the list it iterates (for server-side lookups). */
interface LoopItem { list: t.Expression; ctx: Ctx; index?: string }

/** One prop value at a call site: Elixir code plus the React expression it came from. */
interface CallArg { code: string; node?: t.Expression; ctx: Ctx }

/** `setX(item)` where item is a map from a list: pushed by key, looked up again in handle_event/3. */
interface Lookup { list: t.Expression; ctx: Ctx; key?: string; line: number; file: string }

/** Template data emitted as a zero-arity function (`defp sidebar_data do ... end`). */
interface DataConst {
  fn: string
  term?: Term
  error?: string
  line: number
  file: string
  used: boolean
  missingIcons: { name: string; line: number }[]
  /** Source expression (absent for JSON imports). */
  node?: t.Node
  /**
   * A module-level literal array the converted markup may not call (its consumer became a TODO); it is emitted
   * anyway, as a public `def` when nothing calls it, so the data survives for the hand-written replacement.
   */
  keep?: boolean
}

interface Unit {
  key: string
  decl: ComponentDecl
  parsed: ParsedFile
  fnName: string
  entry: boolean
  props: Map<string, { attr: string; defaultNode?: t.Expression }>
  propsParam?: string
  needs: Map<string, Need>
  restInclude: Set<string>
  hasRest: boolean
  hasChildren: boolean
  callSites: Map<string, CallArg>[]
  /** Rendered inside a loop or table row: takes `item_key` and suffixes its generated ids with it. */
  keyed: boolean
  /** Props used only at conversion time (TanStack `columns`): callers pass no attr. */
  consumedProps: Set<string>
  heex: string
}

interface StateInfo { assign: string; init?: t.Expression; code?: string; unit: Unit; line: number; scope: Map<string, Binding> }

type ClauseStyle = "push" | "value" | "open" | "action" | "select"

/** Data keys (in preference order) that identify a row when an object state value travels through an event. */
const identityKeys = ["id", "value", "slug", "key", "name", "title", "label", "url", "href"]

/** Recharts chart → chart_canvas kind, and the series element it accepts. */
const rechartsKinds: Record<string, { kind: string; series: string }> = {
  AreaChart: { kind: "area", series: "Area" },
  BarChart: { kind: "bar", series: "Bar" },
  LineChart: { kind: "line", series: "Line" },
}

/** Runtime libraries the converter never translates, with where their replacement is documented. */
const libraryRules: [RegExp, string, string][] = [
  [/^@tanstack\/(react-)?table/, "TanStack Table: columns, cell renderers, sorting/selection/pagination state are not converted; render rows with table/1 from server-side assigns", "usage-rules/data-tables.md"],
  [/^@dnd-kit\//, "dnd-kit drag and drop: no LiveView equivalent is emitted; reorder through a phx-hook that pushes the new order and keep the order in assigns", "usage-rules.md#state-model-applies-to-every-interactive-family"],
  [/^recharts$/, "Recharts: only AreaChart/BarChart/LineChart with static data inside ChartContainer become chart_canvas", "usage-rules/components.md (`chart` row)"],
  [/^zod$/, "zod schemas: validate with an Ecto changeset instead", "usage-rules/forms.md"],
  [/^@tanstack\/react-query|^swr$/, "client data fetching: load data in mount/handle_params instead", "usage-rules.md#state-model-applies-to-every-interactive-family"],
]

const reserved: Record<string, true> = {
  do: true, end: true, fn: true, when: true, in: true, not: true, and: true, or: true, true: true, false: true, nil: true,
  catch: true, rescue: true, after: true, else: true, receive: true, try: true, case: true, cond: true, if: true,
  unless: true, for: true, with: true, quote: true, import: true, alias: true, require: true, def: true, defp: true,
}
const reservedFunctions: Record<string, true> = {
  render: true, mount: true, handle_event: true, handle_info: true, handle_params: true, put_ui: true, template_icon: true,
  form: true, link: true, live_component: true, live_title: true, inputs_for: true, focus_wrap: true, dynamic_tag: true,
  async_result: true, live_file_input: true, intersperse: true, flash: true, flash_group: true, header: true, list: true,
  show: true, hide: true, translate_error: true, translate_errors: true, error: true,
}

const htmlAttrNames: Record<string, string> = {
  className: "class", htmlFor: "for", tabIndex: "tabindex", autoComplete: "autocomplete", autoFocus: "autofocus",
  readOnly: "readonly", maxLength: "maxlength", minLength: "minlength", colSpan: "colspan", rowSpan: "rowspan",
  srcSet: "srcset", crossOrigin: "crossorigin", encType: "enctype", acceptCharset: "accept-charset",
  spellCheck: "spellcheck", contentEditable: "contenteditable", inputMode: "inputmode", enterKeyHint: "enterkeyhint",
  autoCapitalize: "autocapitalize", noValidate: "novalidate", formAction: "formaction", dateTime: "datetime",
  xlinkHref: "xlink:href", defaultValue: "value", defaultChecked: "checked", referrerPolicy: "referrerpolicy",
}
const svgCamelAttrs = /^(stroke[A-Z]|fill[A-Z]|clip[A-Z]|stop[A-Z]|font[A-Z]|text[A-Z]|dominantBaseline|alignmentBaseline|baselineShift|colorInterpolation|floodColor|floodOpacity|lightingColor|markerEnd|markerMid|markerStart|paintOrder|pointerEvents|shapeRendering|vectorEffect|wordSpacing|letterSpacing|writingMode)/
const ignoredProps: Record<string, true> = { key: true, suppressHydrationWarning: true }
const iconProviderProps: Record<string, true> = { lucide: true, tabler: true, hugeicons: true, phosphor: true, remixicon: true }

function jsxName(name: t.JSXOpeningElement["name"]): string {
  if (name.type === "JSXIdentifier") return name.name
  if (name.type === "JSXNamespacedName") return `${name.namespace.name}:${name.name.name}`
  return `${jsxName(name.object as t.JSXOpeningElement["name"])}.${name.property.name}`
}

function cleanJsxText(value: string): string {
  const lines = value.split(/\r\n|\n|\r/)
  let lastNonEmpty = 0
  lines.forEach((line, index) => { if (/[^ \t]/.test(line)) lastNonEmpty = index })
  let result = ""
  lines.forEach((line, index) => {
    let trimmed = line.replace(/\t/g, " ")
    if (index !== 0) trimmed = trimmed.replace(/^ +/, "")
    if (index !== lines.length - 1) trimmed = trimmed.replace(/ +$/, "")
    if (trimmed) result += trimmed + (index !== lastNonEmpty ? " " : "")
  })
  return result
}

function unwrap(node: t.Expression): t.Expression {
  let current = node
  while (current.type === "TSAsExpression" || current.type === "TSSatisfiesExpression" || current.type === "TSNonNullExpression" || current.type === "ParenthesizedExpression") {
    current = current.expression
  }
  return current
}

function isJsx(node: t.Node | null | undefined): node is t.JSXElement | t.JSXFragment {
  return node?.type === "JSXElement" || node?.type === "JSXFragment"
}

/** HEEx attribute value for Elixir code: a plain string literal stays quoted, anything else is `{code}`. */
function codeAttr(code: string): string {
  return /^"(?:[^"\\#]|#(?!\{))*"$/.test(code) ? code : `{${code}}`
}

/** Drops `:let={x}` whose variable the children never use (unused variables fail --warnings-as-errors). */
function pruneUnusedLets(nodes: HNode[]): void {
  for (const node of nodes) {
    if (node.k === "if") {
      pruneUnusedLets(node.then)
      pruneUnusedLets(node.else)
    } else if (node.k === "for") {
      pruneUnusedLets(node.body)
    } else if (node.k === "el") {
      pruneUnusedLets(node.children)
      const index = node.attrs.findIndex(attr => attr.name === ":let")
      const variable = index >= 0 ? node.attrs[index].value?.match(/^\{(\w+)\}$/)?.[1] : undefined
      const text = printNodes(node.children, 0).replace(/<%!--[\s\S]*?--%>/g, "")
      if (variable && !new RegExp(`(?<![\\w@.:])${variable}\\b`).test(text)) node.attrs.splice(index, 1)
    }
  }
}

function containsJsx(node: t.Node | null | undefined): boolean {
  if (!node) return false
  if (isJsx(node)) return true
  if (node.type === "ConditionalExpression") return containsJsx(node.consequent) || containsJsx(node.alternate)
  if (node.type === "LogicalExpression") return containsJsx(node.right)
  if (node.type === "ParenthesizedExpression") return containsJsx(node.expression)
  return false
}

function elixirVar(name: string): string {
  const snake = toSnakeCase(name).replace(/[^a-z0-9_]/g, "") || "value"
  return reserved[snake] ? `${snake}_` : snake
}

/** Opacity literal for HEEx/Elixir: `1` → `1.0` so lists stay floats like the source (`stopOpacity={1.0}`). */
function chartNumber(value: number): string {
  return Number.isInteger(value) ? value.toFixed(1) : String(value)
}

function negate(cond: string): string {
  return /^[@\w.()\[\]:"]+$/.test(cond) ? `!${cond}` : `!(${cond})`
}

function stripCodeForComment(text: string): string {
  return text.replace(/--%>/g, "-- %>").replace(/\s+/g, " ").trim()
}

export class Converter {
  private parsed = new Map<string, ParsedFile>()
  private units = new Map<string, Unit>()
  private todos: Todo[] = []
  private notes: Note[] = []
  private mapping = new Map<string, { liveview: string; count: number }>()
  /** `keepValue`: a single-select toggle group feeds the `value` clause; its deselect payload (`""`) keeps the assign. */
  private clauses = new Map<string, { styles: Set<ClauseStyle>; assign?: string; uiKey?: string; body?: string; line: number; lookups?: Map<string, Lookup>; keepValue?: boolean }>()
  private uiDefaults = false
  private states = new Map<string, StateInfo>()
  private forms = new Map<string, { as: string; line: number; file: string }>()
  private consts = new Map<string, DataConst>()
  private iconKeys = new Set<string>()
  /**
   * Row keys templates read with `x.key` where the row's list is unknown; only keys that no sample data has at all
   * are added (nil) to row maps. Keys read on rows of a known list are in `listKeys`, per list.
   */
  private accessedKeys = new Set<string>()
  /** Row keys read on the items of a known sample-data list (`item.title` in `items.map(item => ...)`). */
  private listKeys = new Map<Term, Set<string>>()
  private ids = new Map<string, number>()
  private qualified = new Set<string>()
  private usesJS = false
  private toaster = false
  private toasterRendered = false
  private inlineIcons = new Map<string, string>()
  private families = new Set<string>()
  /** JSX/expression nodes rendered into the output (per pass), for the source completeness check. */
  private visited = new Set<t.Node>()
  /** Nodes reported by a TODO or translated wholesale (chart parts); their subtree is accounted for. */
  private accounted = new Set<t.Node>()
  /** Imported bindings (`file#local`) whose use the converter translated (recharts parts, useIsMobile). */
  private handledImports = new Set<string>()
  private placeholders: Placeholder[] = []
  private viewport = false
  /** TanStack tables converted to DataTable in this pass, and the JSX each of their parts replaces. */
  private tables: TableSpec[] = []
  private tableParts = new Map<t.Node, { kind: TablePartKind; spec: TableSpec }>()
  /** Source completeness wording for column definitions left out on purpose (dnd-kit drag handles). */
  private columnNotes = new Map<t.Node, string>()

  constructor(private meta: Metadata, private set: SourceSet, private opts: ConvertOptions) {}

  // ---------------------------------------------------------------- files & units

  private file(file: string): ParsedFile {
    let parsed = this.parsed.get(file)
    if (!parsed) {
      parsed = parseSource(file, this.set.files.get(file)!)
      this.parsed.set(file, parsed)
    }
    return parsed
  }

  private todo(ctx: Ctx | { unit: Unit } | undefined, node: t.Node | null | undefined, reason: string, rule: string = rules.mapping): HNode {
    const file = ctx?.unit.decl.file ?? this.set.entry
    const line = lineOf(node)
    this.todos.push({ file, line, reason, rule })
    if (node) this.accounted.add(node)
    return { k: "comment", v: `TODO(shadcn-to-liveview): ${stripCodeForComment(reason)} See ${rule}.` }
  }

  private note(ctx: Ctx, node: t.Node | null | undefined, message: string): void {
    this.notes.push({ file: ctx.unit.decl.file, line: lineOf(node), message })
  }

  private mapped(react: string, liveview: string): void {
    const entry = this.mapping.get(react)
    if (entry) entry.count++
    else this.mapping.set(react, { liveview, count: 1 })
  }

  private unitFor(decl: ComponentDecl, entry = false): Unit {
    const key = `${decl.file}#${decl.name}`
    let unit = this.units.get(key)
    if (unit) return unit
    let fnName = toSnakeCase(decl.name)
    if (this.meta.functions.has(fnName) || reservedFunctions[fnName]) fnName = `${fnName}_section`
    const taken = new Set([...this.units.values()].map(other => other.fnName))
    for (let n = 2; taken.has(fnName); n++) fnName = `${toSnakeCase(decl.name)}_${n}`
    unit = {
      key, decl, parsed: this.file(decl.file), fnName, entry, props: new Map(), needs: new Map(), restInclude: new Set(),
      hasRest: false, hasChildren: false, callSites: [], heex: "", keyed: false, consumedProps: new Set(),
    }
    this.readProps(unit)
    this.units.set(key, unit)
    return unit
  }

  private readProps(unit: Unit): void {
    const param = unit.decl.node.params[0]
    if (!param) return
    const pattern = param.type === "AssignmentPattern" ? param.left : param
    if (pattern.type === "Identifier") {
      unit.propsParam = pattern.name
      return
    }
    if (pattern.type !== "ObjectPattern") return
    for (const property of pattern.properties) {
      if (property.type === "RestElement") {
        if (property.argument.type === "Identifier") {
          unit.hasRest = true
          unit.props.set(property.argument.name, { attr: "rest" })
        }
        continue
      }
      const key = property.key.type === "Identifier" ? property.key.name : property.key.type === "StringLiteral" ? property.key.value : undefined
      if (!key) continue
      let local = key
      let defaultNode: t.Expression | undefined
      const value = property.value
      if (value.type === "Identifier") local = value.name
      else if (value.type === "AssignmentPattern" && value.left.type === "Identifier") {
        local = value.left.name
        defaultNode = value.right
      }
      if (key === "children") {
        unit.hasChildren = true
        unit.props.set(local, { attr: "inner_block" })
      } else {
        unit.props.set(local, { attr: key === "className" ? "class" : elixirVar(key), defaultNode })
      }
    }
  }

  // ---------------------------------------------------------------- top level

  convert(): ConvertResult {
    const entryFile = this.file(this.set.entry)
    const entryDecl = (entryFile.defaultExport && entryFile.components.get(entryFile.defaultExport))
      ?? [...entryFile.components.values()].find(component => component.exported)
      ?? [...entryFile.components.values()][0]
    if (!entryDecl) throw new Error(`${this.set.entry}: no React component found`)
    const entry = this.unitFor(entryDecl, true)

    // Context/assign needs propagate from callees to callers, so render until they are stable.
    for (let pass = 0; pass < 6; pass++) {
      const before = this.needsSignature()
      this.resetPass()
      const queue: Unit[] = [entry]
      const seen = new Set<string>()
      while (queue.length) {
        const unit = queue.shift()!
        if (seen.has(unit.key)) continue
        seen.add(unit.key)
        this.renderUnit(unit)
        for (const other of this.units.values()) if (!seen.has(other.key) && this.referenced(other)) queue.push(other)
      }
      if (this.needsSignature() === before && pass > 0) break
    }
    return this.assemble(entry)
  }

  private referenced(unit: Unit): boolean {
    return unit.callSites.length > 0 || unit.entry
  }

  private needsSignature(): string {
    return [...this.units.values()].map(unit => `${unit.key}:${[...unit.needs.keys()].sort().join(",")}:${[...unit.restInclude].sort().join(",")}`).join(";")
  }

  private resetPass(): void {
    this.todos = []
    this.notes = []
    this.mapping.clear()
    this.clauses.clear()
    this.ids.clear()
    this.states.clear()
    this.forms.clear()
    this.qualified.clear()
    this.families.clear()
    this.uiDefaults = false
    this.usesJS = false
    this.pending = []
    this.visited.clear()
    this.accounted.clear()
    this.handledImports.clear()
    this.placeholders = []
    this.viewport = false
    this.tables = []
    this.tableParts.clear()
    this.columnNotes.clear()
    for (const constant of this.consts.values()) constant.used = false
    for (const unit of this.units.values()) unit.callSites = []
  }

  private renderUnit(unit: Unit): void {
    const ctx: Ctx = { unit, scope: new Map(), contexts: new Map(), loopIndexes: [], idKey: unit.keyed ? "@item_key" : undefined }
    for (const [local, prop] of unit.props) {
      if (prop.attr === "rest") ctx.scope.set(local, { b: "rest" })
      else if (prop.attr === "inner_block") ctx.scope.set(local, { b: "children" })
      else ctx.scope.set(local, { b: "code", code: `@${prop.attr}` })
    }
    const body = unit.decl.node.body
    let result: t.Expression | null | undefined
    // `if (!team) return null` / `if (cond) return <X/>` before the final return: conditional branches.
    const guards: { cond: string; then: HNode[] }[] = []
    if (body.type === "BlockStatement") {
      for (const statement of body.body) {
        if (statement.type === "ReturnStatement") {
          result = statement.argument
          break
        }
        const guard = this.earlyReturn(statement, ctx)
        if (guard) guards.push(guard)
        else this.bodyStatement(statement, ctx)
      }
    } else {
      result = body
    }
    let nodes: HNode[]
    if (!result) nodes = [this.todo(ctx, unit.decl.node, `${unit.decl.name} has no final \`return\` of JSX`)]
    else nodes = this.child(result, ctx)
    for (const guard of guards.reverse()) nodes = this.ifElse(guard.cond, guard.then, nodes)
    if (unit.entry && this.toaster && !this.toasterRendered) nodes.push(el(".toaster", [{ name: "id", value: '"toaster"' }]))
    pruneUnusedLets(nodes)
    unit.heex = printNodes(nodes, 4)
  }

  /** `if (cond) return null|<JSX/>` (no else): the rest of the component renders only when `cond` is false. */
  private earlyReturn(statement: t.Statement, ctx: Ctx): { cond: string; then: HNode[] } | undefined {
    if (statement.type !== "IfStatement" || statement.alternate) return undefined
    const consequent = statement.consequent.type === "BlockStatement" && statement.consequent.body.length === 1 ? statement.consequent.body[0] : statement.consequent
    if (consequent.type !== "ReturnStatement") return undefined
    const argument = consequent.argument ? unwrap(consequent.argument) : undefined
    if (argument && argument.type !== "NullLiteral" && !isJsx(argument)) return undefined
    try {
      const cond = this.condition(statement.test, ctx)
      const then = argument && isJsx(argument) ? this.child(argument, ctx) : []
      this.visited.add(statement)
      this.mapped("early `if (...) return`", ":if around the rest of the template")
      return { cond, then }
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      return undefined
    }
  }

  private bodyStatement(statement: t.Statement, ctx: Ctx): void {
    if (statement.type === "VariableDeclaration") {
      for (const declarator of statement.declarations) this.localDeclaration(declarator, ctx)
      return
    }
    if (statement.type === "ExpressionStatement" && statement.expression.type === "CallExpression") {
      const callee = this.calleeName(statement.expression.callee)
      if (/^(React\.)?use(Effect|LayoutEffect)$/.test(callee)) {
        this.pendingTodo(ctx, statement, `\`${callee}\` side effect is not converted; move it to mount/handle_info or a JS hook`, rules.state)
        return
      }
    }
    if (statement.type === "FunctionDeclaration" || statement.type === "EmptyStatement") {
      if (statement.type === "FunctionDeclaration" && statement.id) ctx.scope.set(statement.id.name, { b: "unknown", reason: `local function \`${statement.id.name}\`` })
      return
    }
    this.pendingTodo(ctx, statement, `statement before \`return\` is not converted (${statement.type}); early returns and branches must be rewritten by hand`)
  }

  private pending: { ctx: Ctx; node: t.Node; reason: string; rule: string }[] = []

  private pendingTodo(ctx: Ctx, node: t.Node, reason: string, rule: string = rules.mapping): void {
    // Recorded in the report; rendered as a comment at the top of the component's template.
    this.todos.push({ file: ctx.unit.decl.file, line: lineOf(node), reason, rule })
    this.accounted.add(node)
    this.pending.push({ ctx, node, reason, rule })
  }

  private calleeName(callee: t.Node): string {
    if (callee.type === "Identifier") return callee.name
    if (callee.type === "MemberExpression" && callee.object.type === "Identifier" && callee.property.type === "Identifier") return `${callee.object.name}.${callee.property.name}`
    return ""
  }

  private localDeclaration(declarator: t.VariableDeclarator, ctx: Ctx): void {
    const init = declarator.init ? unwrap(declarator.init) : undefined
    const id = declarator.id
    const callee = init?.type === "CallExpression" ? this.calleeName(init.callee) : ""
    if (/^(React\.)?useState$/.test(callee) && id.type === "ArrayPattern" && init?.type === "CallExpression") {
      const [value, setter] = id.elements
      if (value?.type !== "Identifier") return
      const assign = this.stateAssign(value.name, ctx.unit)
      const argument = init.arguments[0]
      const initial = argument && argument.type !== "SpreadElement" && argument.type !== "ArgumentPlaceholder"
        ? unwrap(argument.type === "ArrowFunctionExpression" && argument.body.type !== "BlockStatement" ? argument.body : argument as t.Expression)
        : undefined
      this.states.set(assign, { assign, init: initial, unit: ctx.unit, line: lineOf(declarator), scope: ctx.scope })
      ctx.scope.set(value.name, { b: "state", assign })
      if (setter?.type === "Identifier") ctx.scope.set(setter.name, { b: "setter", assign })
      return
    }
    if (/^(React\.)?useId$/.test(callee) && id.type === "Identifier") {
      ctx.scope.set(id.name, { b: "code", code: elixirString(this.genId(ctx, id.name)) })
      return
    }
    if (callee === "useSidebar") {
      if (id.type === "Identifier") ctx.scope.set(id.name, { b: "sidebar" })
      else if (id.type === "ObjectPattern") {
        for (const property of id.properties) {
          if (property.type !== "ObjectProperty" || property.key.type !== "Identifier" || property.value.type !== "Identifier") continue
          ctx.scope.set(property.value.name, this.sidebarField(property.key.name, ctx, property))
        }
      }
      return
    }
    if (/^use(Is)?Mobile$/.test(callee) && id.type === "Identifier") {
      this.handledImports.add(`${ctx.unit.parsed.file}#${callee}`)
      ctx.scope.set(id.name, this.mobileBinding(ctx, declarator))
      return
    }
    if (/^(React\.)?useMemo$/.test(callee) && id.type === "Identifier" && init?.type === "CallExpression") {
      const fn = init.arguments[0]
      if (fn?.type === "ArrowFunctionExpression" && fn.body.type !== "BlockStatement") {
        ctx.scope.set(id.name, { b: "local", node: fn.body, ctx })
        return
      }
    }
    if (tableHooks.test(callee) && id.type === "Identifier" && init?.type === "CallExpression" && this.tanstackTable(id.name, declarator, init, ctx)) return
    if (/^(React\.)?use[A-Z]/.test(callee) || /^use[A-Z]/.test(callee)) {
      this.bindPattern(id, { b: "unknown", reason: `\`${callee}()\` result` }, ctx)
      this.pendingTodo(ctx, declarator, `React hook \`${callee}\` has no LiveView equivalent; keep the value in assigns`, rules.state)
      return
    }
    if (id.type === "Identifier" && init) {
      // Literal data inside a component (`const items = [...]`) becomes a module-level function too.
      if (init.type === "ArrayExpression" || init.type === "ObjectExpression") {
        const key = this.registerConst(ctx.unit.parsed, id.name, init, ctx.unit.fnName)
        if (!this.consts.get(key)!.error) {
          ctx.scope.set(id.name, { b: "const", key })
          return
        }
      }
      ctx.scope.set(id.name, { b: "local", node: init, ctx: { ...ctx } })
      return
    }
    this.bindPattern(id, { b: "unknown", reason: "destructured local" }, ctx)
  }

  // ---------------------------------------------------------------- TanStack Table → ShadcnLiveview.DataTable

  /**
   * `const table = useReactTable({ data, columns, ... })` (v8) or `useTable(...)` (v9) whose columns are literal
   * definitions and whose grid (`getHeaderGroups`/`getRowModel`) sits in one <Table>: the instance becomes a
   * `DataTable.State` assign plus a page-rows assign, and the grid, pagination footer, column menu and column
   * filter inputs around its calls become data_table components. Anything else keeps the generic hook TODO.
   */
  private tanstackTable(name: string, declarator: t.VariableDeclarator, init: t.CallExpression, ctx: Ctx): boolean {
    const imported = ctx.unit.parsed.imports.get(this.calleeName(init.callee))
    const options = init.arguments[0] && unwrapTs(init.arguments[0])
    if (!imported || !tanstackSource.test(imported.source) || options?.type !== "ObjectExpression") return false
    const source = this.columnSource(propertyValue(options, "columns"), ctx)
    const array = source && columnArray(source.node)
    const parsedColumns = array && parseColumns(array)
    if (!source || !parsedColumns) return false

    const uses = tableUses(ctx.unit.decl.node, name)
    const enclosing = (chain: t.JSXElement[], component: string) =>
      [...chain].reverse().find(element => this.importedName(jsxName(element.openingElement.name), ctx) === component)
    const grids = new Set(uses.filter(use => use.kind === "grid").map(use => enclosing(use.elements, "Table")))
    const [grid] = grids
    if (grids.size !== 1 || !grid) return false

    const columnsUnit = source.parsed === ctx.unit.parsed ? ctx.unit : { ...ctx.unit, parsed: source.parsed, decl: { ...ctx.unit.decl, file: source.parsed.file } }
    const columnsCtx: Ctx = { unit: columnsUnit, scope: new Map(), contexts: ctx.contexts, loopIndexes: [] }
    const selection = ["toggleSelected", "getIsSelected", "toggleAllPageRowsSelected", "getIsAllPageRowsSelected", "toggleAllRowsSelected", "getIsAllRowsSelected"]
    const sortableComponent = (element: t.JSXElement) => {
      const decl = source.parsed.components.get(jsxName(element.openingElement.name))
      return !!decl && callsAny(decl.node, ["useSortable", "useDraggable"])
    }
    const columns = parsedColumns.map(column => {
      let kind: TableSpec["columns"][number]["kind"] = "data"
      if ([column.cell, column.header].some(renderer => renderer && callsAny(renderer, selection))) kind = "select"
      else if (column.cell && findElement(column.cell, sortableComponent)) kind = "drag"
      else if (!column.accessor && column.cell && findElement(column.cell, element => this.importedName(jsxName(element.openingElement.name), columnsCtx) === "DropdownMenu")) kind = "actions"
      return { column, kind }
    })

    // React state passed to the table (`state: { sorting, pagination, ... }`) is now DataTable state.
    const initial = new Map<string, t.Node>()
    const stateOption = propertyValue(options, "state")
    for (const entry of stateOption?.type === "ObjectExpression" ? stateOption.properties : []) {
      if (entry.type !== "ObjectProperty" || entry.key.type !== "Identifier" || entry.value.type !== "Identifier") continue
      const binding = ctx.scope.get(entry.value.name)
      if (binding?.b !== "state") continue
      const info = this.states.get(binding.assign)
      if (info?.init) initial.set(entry.key.name, unwrapTs(info.init))
      this.states.delete(binding.assign)
    }
    const initialState = propertyValue(options, "initialState")
    for (const key of ["pagination", "sorting", "columnVisibility"]) {
      const value = initialState?.type === "ObjectExpression" ? propertyValue(initialState, key) : undefined
      if (value && !initial.has(key)) initial.set(key, value)
    }

    const id = this.genId(ctx, kebab(ctx.unit.decl.name).includes("table") ? "" : "table")
    const assign = this.stateAssign(name, ctx.unit)
    const newOptions = [`id: ${elixirString(id)}`, `event: ${elixirString(id)}`]
    const sortable = columns.filter(entry => entry.kind === "data" && this.headerInfo(entry.column).sortable).map(entry => entry.column.field)
    if (sortable.length) newOptions.push(`sortable: [${sortable.map(elixirString).join(", ")}]`)
    const sorting = initial.get("sorting")
    const firstSort = sorting?.type === "ArrayExpression" && sorting.elements[0] ? unwrapTs(sorting.elements[0]) : undefined
    const sortId = firstSort?.type === "ObjectExpression" ? propertyValue(firstSort, "id") : undefined
    if (sortId?.type === "StringLiteral" && sortable.includes(sortId.value)) {
      newOptions.push(`sort: ${elixirString(sortId.value)}`)
      const desc = firstSort?.type === "ObjectExpression" ? propertyValue(firstSort, "desc") : undefined
      if (desc?.type === "BooleanLiteral" && desc.value) newOptions.push("dir: :desc")
    }
    const pagination = initial.get("pagination")
    const pageSize = pagination?.type === "ObjectExpression" ? propertyValue(pagination, "pageSize") : undefined
    if (pageSize?.type === "NumericLiteral" && pageSize.value !== 10) newOptions.push(`page_size: ${pageSize.value}`)
    const visibility = initial.get("columnVisibility")
    const hidden = visibility?.type === "ObjectExpression"
      ? visibility.properties.flatMap(entry => (entry.type === "ObjectProperty" && entry.key.type === "Identifier" && entry.value.type === "BooleanLiteral" && !entry.value.value ? [entry.key.name] : []))
      : []
    if (hidden.length) newOptions.push(`hidden: [${hidden.map(elixirString).join(", ")}]`)
    let rowKey = "id"
    const getRowId = propertyValue(options, "getRowId")
    if ((getRowId?.type === "ArrowFunctionExpression" || getRowId?.type === "FunctionExpression") && getRowId.params[0]?.type === "Identifier") {
      const param = getRowId.params[0].name
      const read = findMember(getRowId.body, param)
      if (read) rowKey = read
    }
    if (rowKey !== "id") newOptions.push(`row_key: ${elixirString(rowKey)}`)

    const spec: TableSpec = {
      id, assign, rowsAssign: `${assign}_rows`, unit: ctx.unit, line: lineOf(declarator), columns, columnsCtx,
      data: propertyValue(options, "data"), scope: ctx.scope, rowKey, newOptions: "",
    }
    const parts: t.Node[] = [grid]
    this.tableParts.set(grid, { kind: "grid", spec })
    const searchable: string[] = []
    for (const use of uses) {
      const part = use.kind === "columns" ? enclosing(use.elements, "DropdownMenu") : use.kind === "search" && use.field ? enclosing(use.elements, "Input") : undefined
      if (!part) continue
      this.tableParts.set(part, { kind: use.kind, spec })
      parts.push(part)
      if (use.field && !searchable.includes(use.field)) searchable.push(use.field)
    }
    if (searchable.length) newOptions.push(`searchable: [${searchable.map(elixirString).join(", ")}]`)
    const footer = commonElement(uses.filter(use => use.kind === "pagination").map(use => use.elements))
    const inside = (outer: t.Node, inner: t.Node) => (outer.start ?? 0) <= (inner.start ?? 0) && (inner.end ?? 0) <= (outer.end ?? 0)
    if (footer && !parts.some(part => inside(footer, part) || inside(part, footer))) this.tableParts.set(footer, { kind: "pagination", spec })
    spec.newOptions = newOptions.join(", ")

    const scope = ctx.scope
    this.states.set(assign, { assign, code: `DataTable.new(${spec.newOptions})`, unit: ctx.unit, line: spec.line, scope })
    this.states.set(spec.rowsAssign, { assign: spec.rowsAssign, code: "[]", unit: ctx.unit, line: spec.line, scope })
    this.addClause(id, "push", { body: `table:${assign}`, line: spec.line })
    this.tables.push(spec)
    ctx.scope.set(name, { b: "table", spec })
    this.visited.add(declarator)
    // `columns` (and `data`, read by load_<table>/1) props are used here, so callers pass no attr for them.
    for (const key of ["columns", "data"]) {
      const option = propertyValue(options, key)
      const prop = option?.type === "Identifier" ? ctx.unit.props.get(option.name) : undefined
      if (prop) ctx.unit.consumedProps.add(prop.attr)
    }
    for (const parsed of new Set([ctx.unit.parsed, source.parsed])) {
      for (const [local, ref] of parsed.imports) if (tanstackSource.test(ref.source)) this.handledImports.add(`${parsed.file}#${local}`)
    }
    this.mapped(`${this.calleeName(init.callee)}() (TanStack Table)`, "DataTable.State assign")
    return true
  }

  /** The expression behind `columns`: a local, a prop (through its call site), a module or imported constant. */
  private columnSource(node: t.Node | undefined, ctx: Ctx, depth = 0): { node: t.Node; parsed: ParsedFile } | undefined {
    const value = node && unwrapTs(node)
    if (!value || depth > 4) return undefined
    if (value.type !== "Identifier") return { node: value, parsed: ctx.unit.parsed }
    const binding = ctx.scope.get(value.name)
    if (binding?.b === "local") return this.columnSource(binding.node, binding.ctx, depth + 1)
    const prop = ctx.unit.props.get(value.name)
    if (prop) {
      const argument = ctx.unit.callSites[0]?.get(prop.attr)
      return argument?.node ? this.columnSource(argument.node, argument.ctx, depth + 1) : undefined
    }
    const constant = ctx.unit.parsed.consts.get(value.name)
    if (constant) return { node: constant, parsed: ctx.unit.parsed }
    const imported = ctx.unit.parsed.imports.get(value.name)
    const kind = imported && classifyImport(this.set, ctx.unit.parsed.file, imported.source, imported.imported)
    if (imported && kind?.kind === "local") {
      const other = this.file(kind.file)
      const otherConstant = other.consts.get(imported.imported)
      if (otherConstant) return { node: otherConstant, parsed: other }
    }
    return undefined
  }

  /** Column label (string header, `title` of a `*ColumnHeader`, or static header text), alignment, sortability. */
  private headerInfo(column: TableColumn): { label: string; headClass?: string; sortable: boolean } {
    const header = column.header && unwrapTs(column.header)
    if (header?.type === "StringLiteral") return { label: header.value, sortable: false }
    if (header?.type !== "ArrowFunctionExpression" && header?.type !== "FunctionExpression") return { label: column.field, sortable: false }
    const columnHeader = findElement(header, element => /ColumnHeader$/.test(jsxName(element.openingElement.name)))
    const title = columnHeader && this.jsxAttrExpr(columnHeader, "title")
    const root = findElement(header, () => true)
    const className = root && this.jsxAttrExpr(root, "className")
    return {
      label: title?.type === "StringLiteral" ? title.value : staticText(header),
      headClass: className?.type === "StringLiteral" ? className.value.match(/\btext-(left|center|right)\b/)?.[0] : undefined,
      sortable: column.enableSorting && (!!columnHeader || callsAny(header, ["toggleSorting"])),
    }
  }

  /** `row` (and `getValue`/the whole cell context) of a cell renderer, with per-row ids for stateful children. */
  private cellCtx(column: TableColumn, spec: TableSpec): Ctx {
    const ctx: Ctx = { ...spec.columnsCtx, scope: new Map(), loopIndexes: [atomAccess("row", elixirVar(spec.rowKey))] }
    const value = atomAccess("row", elixirVar(column.field))
    if (column.accessor) this.accessedKeys.add(elixirVar(column.field))
    const renderer = column.cell && unwrapTs(column.cell)
    if (renderer?.type !== "ArrowFunctionExpression" && renderer?.type !== "FunctionExpression") return ctx
    const param = renderer.params[0]
    if (param?.type === "Identifier") ctx.scope.set(param.name, { b: "cellInfo", row: "row", value })
    for (const property of param?.type === "ObjectPattern" ? param.properties : []) {
      if (property.type !== "ObjectProperty" || property.key.type !== "Identifier" || property.value.type !== "Identifier") continue
      const key = property.key.name
      ctx.scope.set(property.value.name, key === "row" ? { b: "tableRow", code: "row" }
        : key === "getValue" || key === "renderValue" ? { b: "cellValue", code: value }
        : { b: "unknown", reason: `TanStack cell context \`${key}\`` })
    }
    if (renderer.body.type === "BlockStatement") {
      for (const statement of renderer.body.body) {
        if (statement.type === "VariableDeclaration") for (const declarator of statement.declarations) this.localDeclaration(declarator, ctx)
      }
    }
    return ctx
  }

  /** Cell renderer body: an expression, or `const`s, `if (cond) return x` guards and a final `return`. */
  private cellNodes(cell: t.Expression, ctx: Ctx): HNode[] {
    const renderer = unwrapTs(cell)
    if (renderer.type !== "ArrowFunctionExpression" && renderer.type !== "FunctionExpression") {
      return [this.todo(ctx, renderer, `TanStack cell \`${this.snippet(renderer, ctx)}\` is not an inline renderer`, rules.tables)]
    }
    if (renderer.body.type !== "BlockStatement") return this.child(renderer.body, ctx)
    const guards: { cond: string; then: HNode[] }[] = []
    let result: t.Expression | null | undefined
    for (const statement of renderer.body.body) {
      if (statement.type === "VariableDeclaration") continue
      if (statement.type === "ReturnStatement") {
        result = statement.argument
        break
      }
      const consequent = statement.type === "IfStatement" && !statement.alternate
        ? (statement.consequent.type === "BlockStatement" && statement.consequent.body.length === 1 ? statement.consequent.body[0] : statement.consequent)
        : undefined
      if (statement.type !== "IfStatement" || consequent?.type !== "ReturnStatement" || !consequent.argument) {
        return [this.todo(ctx, statement, `statement in a TanStack cell renderer is not converted (${statement.type})`, rules.tables)]
      }
      try {
        guards.push({ cond: this.condition(statement.test, ctx), then: this.child(consequent.argument, ctx) })
        this.visited.add(statement)
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        return [this.todo(ctx, statement, `TanStack cell condition: ${error.message}`, rules.tables)]
      }
    }
    let nodes = result ? this.child(result, ctx) : []
    for (const guard of guards.reverse()) nodes = this.ifElse(guard.cond, guard.then, nodes)
    return nodes
  }

  /** The TanStack row behind `row`, `row.original`, `info.row` or `info.row.original`: its Elixir variable. */
  private tableRowCode(node: t.Node, ctx: Ctx): string | undefined {
    const value = unwrapTs(node)
    if (value.type === "Identifier") {
      const binding = this.lookup(value.name, ctx)
      return binding?.b === "tableRow" ? binding.code : undefined
    }
    if ((value.type !== "MemberExpression" && value.type !== "OptionalMemberExpression") || value.computed || value.property.type !== "Identifier") return undefined
    if (value.property.name === "original") return this.tableRowCode(value.object, ctx)
    if (value.property.name !== "row" || value.object.type !== "Identifier") return undefined
    const binding = this.lookup(value.object.name, ctx)
    return binding?.b === "cellInfo" ? binding.row : undefined
  }

  private tablePart(node: t.JSXElement, part: { kind: TablePartKind; spec: TableSpec }, ctx: Ctx): HNode[] {
    const { spec } = part
    this.accounted.add(node)
    this.families.add("data_table")
    const state: HAttr = { name: "state", value: `{${this.assignRef(ctx, spec.assign)}}` }
    const selectable: HAttr[] = spec.columns.some(entry => entry.kind === "select") ? [{ name: "selectable" }] : []
    const literal = (element: t.JSXElement | undefined, name: string) => {
      const value = element && this.jsxAttrExpr(element, name)
      return value?.type === "StringLiteral" ? value.value : undefined
    }
    const optional = (name: string, value: string | undefined): HAttr[] => (value ? [{ name, value: quoteAttr(value) }] : [])
    const named = (component: string) => findElement(node, element => this.importedName(jsxName(element.openingElement.name), ctx) === component)
    switch (part.kind) {
      case "pagination":
        this.mapped("TanStack pagination controls", "data_table_pagination")
        return [el(".data_table_pagination", [state, ...selectable, ...optional("class", literal(node, "className"))])]
      case "columns": {
        this.mapped("TanStack column visibility menu", "data_table_view_options")
        const fields = spec.columns.filter(entry => entry.kind === "data" && entry.column.accessor && entry.column.enableHiding).map(entry => elixirString(entry.column.field))
        return [el(".data_table_view_options", [state, { name: "columns", value: `{[${fields.join(", ")}]}` }, ...optional("content_class", literal(named("DropdownMenuContent"), "className"))])]
      }
      case "search":
        this.mapped("TanStack column filter input", "data_table_search")
        return [el(".data_table_search", [state, ...optional("placeholder", literal(node, "placeholder")), ...optional("input_class", literal(node, "className"))])]
      case "grid":
        return [this.dataTableElement(node, spec, ctx, [state, ...selectable, ...optional("header_class", literal(named("TableHeader"), "className"))])]
    }
  }

  private dataTableElement(node: t.JSXElement, spec: TableSpec, ctx: Ctx, attrs: HAttr[]): HElement {
    const slots: HNode[] = []
    for (const { column, kind } of spec.columns) {
      if (kind === "drag") {
        this.columnNotes.set(column.node, `TanStack column \`${column.field}\` (lines ${lineOf(column.node)}-${column.node.loc?.end.line ?? lineOf(column.node)}) is a dnd-kit drag handle: row reordering is not converted; reorder through a phx-hook that pushes the new order and keep the order in assigns`)
        continue
      }
      this.accounted.add(column.node)
      if (kind === "select") continue
      const cellCtx = this.cellCtx(column, spec)
      if (kind === "actions") {
        slots.push(this.rowActions(column, cellCtx))
        continue
      }
      const header = this.headerInfo(column)
      const colAttrs: HAttr[] = [{ name: "field", value: quoteAttr(column.field) }, { name: "label", value: quoteAttr(header.label) }]
      if (header.headClass) colAttrs.push({ name: "head_class", value: quoteAttr(header.headClass) })
      const body = column.cell ? this.cellNodes(column.cell, cellCtx) : []
      if (body.length) colAttrs.unshift({ name: ":let", value: "{row}" })
      slots.push(el(":col", colAttrs, body))
      this.mapped("TanStack column", "<:col>")
    }
    const label = spec.columns.find(entry => entry.kind === "data" && ["title", "name", "header", "label", "email"].includes(entry.column.field))
    if (label) attrs.push({ name: "row_label", value: quoteAttr(label.column.field) })
    attrs.splice(1, 0, { name: "rows", value: `{${this.assignRef(ctx, spec.rowsAssign)}}` })
    this.mapped(`<${jsxName(node.openingElement.name)}> with TanStack rows`, "data_table")
    return el(".data_table", attrs, slots)
  }

  /** Actions column: the DropdownMenuContent items become the `<:row_actions>` slot (the trigger is built in). */
  private rowActions(column: TableColumn, ctx: Ctx): HNode {
    const content = findElement(column.cell!, element => this.importedName(jsxName(element.openingElement.name), ctx) === "DropdownMenuContent")
    if (!content) return this.todo(ctx, column.node, `TanStack actions column \`${column.field}\` has no DropdownMenuContent`, rules.tables)
    this.visited.add(content)
    this.mapped("TanStack actions column (DropdownMenu)", "<:row_actions>")
    const className = this.jsxAttrExpr(content, "className")
    const attrs: HAttr[] = [{ name: ":let", value: "{row}" }]
    if (className?.type === "StringLiteral") attrs.push({ name: "class", value: quoteAttr(className.value) })
    return el(":row_actions", attrs, this.children(content.children, ctx))
  }

  private bindPattern(pattern: t.LVal | t.PatternLike | t.Node, binding: Binding, ctx: Ctx): void {
    if (pattern.type === "Identifier") ctx.scope.set(pattern.name, binding)
    else if (pattern.type === "ObjectPattern") for (const property of pattern.properties) this.bindPattern(property.type === "RestElement" ? property.argument : property.value, binding, ctx)
    else if (pattern.type === "ArrayPattern") for (const element of pattern.elements) if (element) this.bindPattern(element, binding, ctx)
    else if (pattern.type === "AssignmentPattern") this.bindPattern(pattern.left, binding, ctx)
  }

  /** `useIsMobile()` / `useSidebar().isMobile`: the `@is_mobile` assign kept current by the generated viewport hook. */
  private mobileBinding(ctx: Ctx, node: t.Node): Binding {
    this.viewport = true
    this.visited.add(node)
    this.note(ctx, node, "`isMobile` became `@is_mobile` (connect param `is_mobile`, then the colocated `.Viewport` hook at max-width 767px).")
    return { b: "state", assign: "is_mobile" }
  }

  private sidebarField(field: string, ctx: Ctx, node: t.Node): Binding {
    switch (field) {
      case "isMobile":
        return this.mobileBinding(ctx, node)
      case "open":
        return { b: "code", code: `${this.contextRef(ctx, "sidebar", node)}.open` }
      case "state":
        return { b: "code", code: `if(${this.contextRef(ctx, "sidebar", node)}.open, do: "expanded", else: "collapsed")` }
      default:
        return { b: "unknown", reason: `\`useSidebar().${field}\` (the sidebar hook owns toggling; use sidebar_trigger)` }
    }
  }

  private stateAssign(name: string, unit: Unit): string {
    let assign = elixirVar(name)
    if (["ui", "flash", "socket", "live_action", "myself", "layout", "uploads", "streams", "inner_content", "inner_block"].includes(assign)) assign = `${assign}_state`
    const existing = this.states.get(assign)
    if (existing && existing.unit !== unit) assign = `${unit.fnName}_${assign}`
    return assign
  }

  // ---------------------------------------------------------------- references

  /** `@name` for an assign owned by the LiveView; sub-components receive it as an attr. */
  private assignRef(ctx: Ctx, assign: string): string {
    // Function-component mode: even the entry receives LiveView state as attrs.
    if (!ctx.unit.entry || this.opts.mode === "component") ctx.unit.needs.set(assign, { attr: assign, kind: "assign" })
    return `@${assign}`
  }

  private contextRef(ctx: Ctx, key: string, _node?: t.Node | null): string {
    const local = ctx.contexts.get(key)
    if (local) return local
    if (!ctx.unit.entry) {
      ctx.unit.needs.set(key, { attr: key, kind: "context" })
      return `@${key}`
    }
    throw new Unsupported(`needs the \`${key}\` context but no enclosing provider is part of this template`)
  }

  private uiState(ctx: Ctx, idCode: string, fallback: string): string {
    this.uiDefaults = true
    return `Map.get(${this.assignRef(ctx, "ui")}, ${idCode}, ${fallback})`
  }

  private genId(ctx: Ctx, base: string): string {
    const stem = `${kebab(ctx.unit.decl.name.replace(/(Page|Example)$/, "")) || "page"}-${kebab(base)}`.replace(/^-|-$/g, "")
    const count = (this.ids.get(stem) ?? 0) + 1
    this.ids.set(stem, count)
    return count === 1 ? stem : `${stem}-${count}`
  }

  /** `-#{index}` per enclosing loop index (and the component's `@item_key`): keeps per-item ids unique. */
  private keySuffix(ctx: Ctx, withKey = true): string {
    return [...ctx.loopIndexes, ...(withKey && ctx.idKey ? [ctx.idKey] : [])].map(index => `-#{${index}}`).join("")
  }

  /** Stable id attribute value (quoted or expression) and its Elixir code, unique per loop iteration. */
  private idFor(ctx: Ctx, explicit: t.Node | null | undefined, base: string): { attr: string; code: string } {
    if (explicit && explicit.type === "StringLiteral" && !ctx.loopIndexes.length) return { attr: quoteAttr(explicit.value), code: elixirString(explicit.value) }
    if (explicit && explicit.type !== "StringLiteral") {
      const code = this.expr(explicit as t.Expression, ctx)
      return { attr: `{${code}}`, code }
    }
    const stem = explicit?.type === "StringLiteral" ? explicit.value : this.genId(ctx, base)
    // Literal ids keep matching their label `for=` inside a keyed component; generated ones take the key.
    const suffix = this.keySuffix(ctx, !explicit)
    if (!suffix) return { attr: quoteAttr(stem), code: elixirString(stem) }
    const code = `"${stem}${suffix}"`
    return { attr: `{${code}}`, code }
  }

  // ---------------------------------------------------------------- expressions

  expr(node: t.Expression | t.Node, ctx: Ctx): string {
    const value = unwrap(node as t.Expression)
    switch (value.type) {
      case "StringLiteral": return elixirString(value.value)
      case "NumericLiteral": return String(value.value)
      case "BooleanLiteral": return String(value.value)
      case "NullLiteral": return "nil"
      case "TemplateLiteral": return this.template(value, ctx)
      case "Identifier": return this.identifier(value, ctx)
      case "MemberExpression":
      case "OptionalMemberExpression": return this.member(value, ctx)
      case "UnaryExpression": {
        if (value.operator === "!") return negate(this.condition(value.argument, ctx))
        if (value.operator === "-") return `-${this.expr(value.argument, ctx)}`
        if (value.operator === "void") return "nil"
        throw new Unsupported(`unary \`${value.operator}\``)
      }
      case "LogicalExpression": {
        // `layout.left ?? 30`: the key may be absent, so read it with Access instead of `.key`.
        const leftNode = unwrap(value.left)
        const left = value.operator !== "&&" && (leftNode.type === "MemberExpression" || leftNode.type === "OptionalMemberExpression") && !leftNode.computed && leftNode.property.type === "Identifier" && !this.staticMember(leftNode, ctx)
          ? `${this.expr(leftNode.object, ctx)}[:${elixirVar(leftNode.property.name)}]`
          : this.expr(value.left, ctx)
        const right = this.expr(value.right, ctx)
        if (value.operator === "&&") return left === "false" ? "false" : left === "true" ? right : `${left} && ${right}`
        return `${left} || ${right}`
      }
      case "BinaryExpression": return this.binary(value, ctx)
      case "ConditionalExpression": {
        const test = this.condition(value.test, ctx)
        if (test === "false") return this.expr(value.alternate, ctx)
        if (test === "true") return this.expr(value.consequent, ctx)
        return `if(${test}, do: ${this.expr(value.consequent, ctx)}, else: ${this.expr(value.alternate, ctx)})`
      }
      case "ArrayExpression": return `[${value.elements.map(element => {
        if (!element || element.type === "SpreadElement") throw new Unsupported("array spread")
        return this.expr(element, ctx)
      }).join(", ")}]`
      case "ObjectExpression": return printTerm(this.term(value, ctx, undefined, []), 0, Infinity)
      case "CallExpression":
      case "OptionalCallExpression": return this.call(value, ctx)
      case "NewExpression": return this.construct(value, ctx)
      default: throw new Unsupported(`expression \`${value.type}\``)
    }
  }

  private template(node: t.TemplateLiteral, ctx: Ctx): string {
    let result = ""
    node.quasis.forEach((quasi, index) => {
      result += (quasi.value.cooked ?? quasi.value.raw).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/#\{/g, "\\#{").replace(/\n/g, "\\n")
      const expression = node.expressions[index]
      if (expression) result += `#{${this.expr(expression, ctx)}}`
    })
    return `"${result}"`
  }

  private identifier(node: t.Identifier, ctx: Ctx): string {
    if (node.name === "undefined") return "nil"
    const binding = this.lookup(node.name, ctx)
    if (!binding) throw new Unsupported(`unknown identifier \`${node.name}\``)
    switch (binding.b) {
      case "code": return binding.code
      case "state": return this.assignRef(ctx, binding.assign)
      case "const": return this.constRef(binding.key)
      case "local": return this.expr(binding.node, { ...binding.ctx, unit: ctx.unit, contexts: ctx.contexts })
      case "icon": return binding.code
      case "sidebar": return this.contextRef(ctx, "sidebar", node)
      case "unknown": throw new Unsupported(binding.reason)
      case "tableRow": return binding.code
      case "table": throw new Unsupported("the TanStack table instance outside the parts converted to data_table")
      case "cellValue": case "cellInfo": throw new Unsupported("a TanStack cell context used as a value")
      default: throw new Unsupported(`\`${node.name}\` cannot be used as a value`)
    }
  }

  private lookup(name: string, ctx: Ctx): Binding | undefined {
    const local = ctx.scope.get(name)
    if (local) return local
    if (ctx.unit.propsParam === name) return { b: "unknown", reason: "the whole props object" }
    const constant = ctx.unit.parsed.consts.get(name)
    if (constant) return { b: "const", key: this.registerConst(ctx.unit.parsed, name, constant) }
    const imported = ctx.unit.parsed.imports.get(name)
    if (imported) {
      const json = resolveJson(this.set, ctx.unit.parsed.file, imported.source)
      if (json) return { b: "const", key: this.registerJson(json, name, imported.imported) }
      const kind = classifyImport(this.set, ctx.unit.parsed.file, imported.source, imported.imported)
      if (kind.kind === "lucide") {
        const icon = this.iconName(imported.imported === "default" ? name : imported.imported)
        if (icon) return { b: "icon", code: elixirString(icon) }
      }
      if (kind.kind === "local") {
        const other = this.file(kind.file)
        const otherConst = other.consts.get(imported.imported)
        if (otherConst) return { b: "const", key: this.registerConst(other, imported.imported, otherConst) }
      }
    }
    return undefined
  }

  private member(node: t.MemberExpression | t.OptionalMemberExpression, ctx: Ctx): string {
    const row = this.tableRowCode(node, ctx)
    if (row) return row
    const resolved = this.staticMember(node, ctx)
    if (resolved) return this.expr(resolved.node, resolved.ctx)
    const property = node.property
    if (node.object.type === "Identifier" && ctx.unit.propsParam === node.object.name && property.type === "Identifier") {
      if (property.name === "children") throw new Unsupported("`props.children` outside JSX children")
      const attr = property.name === "className" ? "class" : elixirVar(property.name)
      ctx.unit.props.set(`props.${property.name}`, { attr })
      return `@${attr}`
    }
    if (node.object.type === "Identifier" && this.lookup(node.object.name, ctx)?.b === "sidebar" && property.type === "Identifier") {
      const field = this.sidebarField(property.name, ctx, node)
      if (field.b === "code") return field.code
      if (field.b === "state") return this.assignRef(ctx, field.assign)
      throw new Unsupported(field.b === "unknown" ? field.reason : "useSidebar field")
    }
    if (!node.computed && property.type === "Identifier" && property.name === "size") return `Enum.count(${this.expr(node.object, ctx)})`
    if (!node.computed && property.type === "Identifier" && property.name === "length") {
      const base = this.expr(node.object, ctx)
      const fn = this.isString(node.object, ctx) ? "String.length" : "length"
      return node.optional ? `${base} && ${fn}(${base})` : `${fn}(${base})`
    }
    const base = this.expr(node.object, ctx)
    if (node.computed) {
      const key = unwrap(property as t.Expression)
      if (key.type === "NumericLiteral") return `Enum.at(${base}, ${key.value})`
      if (key.type === "StringLiteral") return atomAccess(base, elixirVar(key.value)).replace(/^(.*)\.(\w+)$/, "$1[:$2]")
      return `${base}[${this.expr(key, ctx)}]`
    }
    if (property.type !== "Identifier") throw new Unsupported("private member")
    const lists = this.rowListsOf(node.object, ctx)
    for (const list of lists) {
      const keys = this.listKeys.get(list) ?? new Set<string>()
      this.listKeys.set(list, keys.add(elixirVar(property.name)))
    }
    if (!lists.length) this.accessedKeys.add(elixirVar(property.name))
    const access = atomAccess(base, elixirVar(property.name))
    return node.optional ? `${base} && ${access}` : access
  }

  /** Sample-data lists whose rows `node` may be: `item` in `data.navMain.map(item => ...)`, or a prop passed such a row. */
  private rowListsOf(node: t.Node, ctx: Ctx, depth = 0): Term[] {
    const value = unwrap(node as t.Expression)
    if (depth > 8 || value.type !== "Identifier") return []
    const binding = this.lookup(value.name, ctx)
    if (binding?.b === "local") return this.rowListsOf(binding.node, binding.ctx, depth + 1)
    if (binding?.b !== "code") return []
    if (binding.item) return this.listTerms(binding.item.list, binding.item.ctx, depth + 1)
    const prop = [...ctx.unit.props.values()].find(info => `@${info.attr}` === binding.code)
    if (!prop) return []
    return ctx.unit.callSites.flatMap(site => {
      const arg = site.get(prop.attr)
      return arg?.node ? this.rowListsOf(arg.node, arg.ctx, depth + 1) : []
    })
  }

  /** Sample-data lists `node` may evaluate to: a constant's list, or `item.items` of rows of known lists. */
  private listTerms(node: t.Node, ctx: Ctx, depth: number): Term[] {
    const term = this.resolveTerm(node, ctx)
    if (term) return term.t === "list" ? [term] : []
    const value = unwrap(node as t.Expression)
    if ((value.type !== "MemberExpression" && value.type !== "OptionalMemberExpression") || value.computed || value.property.type !== "Identifier") return []
    const key = elixirVar(value.property.name)
    return this.rowListsOf(value.object, ctx, depth + 1).flatMap(list => (list.t === "list" ? list.items : [])).flatMap(row => {
      const nested = row.t === "map" ? row.entries.find(([name]) => name === key)?.[1] : undefined
      return nested?.t === "list" ? [nested] : []
    })
  }

  private binary(node: t.BinaryExpression, ctx: Ctx): string {
    if (node.left.type === "PrivateName") throw new Unsupported("private name")
    const left = this.expr(node.left, ctx)
    const right = this.expr(node.right, ctx)
    switch (node.operator) {
      case "===": case "==": return `${left} == ${right}`
      case "!==": case "!=": return `${left} != ${right}`
      case "<": case ">": case "<=": case ">=": case "-": case "*": case "/": return `${left} ${node.operator} ${right}`
      case "%": return `rem(${left}, ${right})`
      case "+": {
        const stringy = (side: t.Node) => side.type === "StringLiteral" || side.type === "TemplateLiteral"
        if (stringy(node.left) || stringy(node.right)) {
          const asString = (code: string, side: t.Node) => (stringy(side) ? code : `to_string(${code})`)
          return `${asString(left, node.left)} <> ${asString(right, node.right)}`
        }
        return `${left} + ${right}`
      }
      default: throw new Unsupported(`operator \`${node.operator}\``)
    }
  }

  /** Condition with JavaScript truthiness for lengths (`items.length` is falsy when 0). */
  condition(node: t.Expression | t.Node, ctx: Ctx): string {
    const value = unwrap(node as t.Expression)
    if ((value.type === "MemberExpression" || value.type === "OptionalMemberExpression") && !value.computed && value.property.type === "Identifier" && value.property.name === "length") {
      return `(${this.expr(value.object, ctx)} || []) != []`
    }
    if (value.type === "LogicalExpression" && value.operator !== "??") {
      const left = this.condition(value.left, ctx)
      const right = this.condition(value.right, ctx)
      if (value.operator === "&&") return left === "false" ? "false" : left === "true" ? right : `${left} && ${right}`
      return `${left} || ${right}`
    }
    if (value.type === "UnaryExpression" && value.operator === "!") {
      const inner = this.condition(value.argument, ctx)
      return inner === "true" ? "false" : inner === "false" ? "true" : negate(inner)
    }
    return this.expr(value, ctx)
  }

  private call(node: t.CallExpression | t.OptionalCallExpression, ctx: Ctx): string {
    const callee = node.callee
    const args = node.arguments.map(argument => {
      if (argument.type === "SpreadElement" || argument.type === "ArgumentPlaceholder") throw new Unsupported("spread arguments")
      return argument as t.Expression
    })
    const name = this.calleeName(callee)
    const cellValue = callee.type === "Identifier" ? this.lookup(callee.name, ctx) : undefined
    if (cellValue?.b === "cellValue") return cellValue.code
    if ((callee.type === "MemberExpression" || callee.type === "OptionalMemberExpression") && callee.property.type === "Identifier" && /^(get|render)Value$/.test(callee.property.name)) {
      // `row.getValue("status")` / `info.getValue()` in a TanStack cell renderer.
      const row = this.tableRowCode(callee.object, ctx)
      if (row && args[0]?.type === "StringLiteral") {
        this.accessedKeys.add(elixirVar(args[0].value))
        return atomAccess(row, elixirVar(args[0].value))
      }
      const info = callee.object.type === "Identifier" ? this.lookup(callee.object.name, ctx) : undefined
      if (info?.b === "cellInfo" && !args.length) return info.value
    }
    if (name === "String") return `to_string(${this.expr(args[0], ctx)})`
    if (name === "Number" || name === "parseInt") return `String.to_integer(${this.expr(args[0], ctx)})`
    if (name === "Math.round") return `round(${this.expr(args[0], ctx)})`
    if (name === "Math.floor") return `floor(${this.expr(args[0], ctx)})`
    if (name === "Math.ceil") return `ceil(${this.expr(args[0], ctx)})`
    if (name === "Math.min" || name === "Math.max") return `${name.slice(5)}(${args.map(arg => this.expr(arg, ctx)).join(", ")})`
    if (name === "Object.keys") return `Map.keys(${this.expr(args[0], ctx)})`
    if (name === "Object.values") return `Map.values(${this.expr(args[0], ctx)})`
    if (name === "Object.entries") return `Enum.map(${this.expr(args[0], ctx)}, fn {key, value} -> [to_string(key), value] end)`
    if (name === "Array.from" && args[0]?.type === "ObjectExpression") {
      const length = args[0].properties.find(property => property.type === "ObjectProperty" && property.key.type === "Identifier" && property.key.name === "length")
      if (length?.type === "ObjectProperty") return `List.duplicate(nil, ${this.expr(length.value as t.Expression, ctx)})`
    }
    if (callee.type === "MemberExpression" || callee.type === "OptionalMemberExpression") {
      const method = callee.property.type === "Identifier" ? callee.property.name : ""
      const target = () => this.expr(callee.object, ctx)
      switch (method) {
        case "toUpperCase": return `String.upcase(${target()})`
        case "toLowerCase": return `String.downcase(${target()})`
        case "trim": return `String.trim(${target()})`
        case "toString": return `to_string(${target()})`
        case "toFixed": return `:erlang.float_to_binary(${target()} / 1, decimals: ${args[0] ? this.expr(args[0], ctx) : "0"})`
        case "charAt": return `String.at(${target()}, ${this.expr(args[0], ctx)})`
        case "split": return `String.split(${target()}, ${this.expr(args[0], ctx)})`
        case "join": return `Enum.join(${target()}, ${args[0] ? this.expr(args[0], ctx) : '","'})`
        case "includes": return this.isString(callee.object, ctx) ? `String.contains?(${target()}, ${this.expr(args[0], ctx)})` : `${this.expr(args[0], ctx)} in ${target()}`
        case "slice": {
          const start = args[0] ? this.expr(args[0], ctx) : "0"
          const kind = this.isString(callee.object, ctx) ? "String" : "Enum"
          return args[1] ? `${kind}.slice(${target()}, ${start}..(${this.expr(args[1], ctx)} - 1)//1)` : `${kind}.slice(${target()}, ${start}..-1//1)`
        }
        case "map": case "filter": case "find": case "some": case "every": {
          const callback = args[0]
          const enumFn = { map: "map", filter: "filter", find: "find", some: "any?", every: "all?" }[method]
          if ((callback?.type === "ArrowFunctionExpression" || callback?.type === "FunctionExpression") && callback.params.length > 1) {
            if (callback.params.length > 2) throw new Unsupported(`\`.${method}\` callback using the array argument`)
            return `${target()} |> Enum.with_index() |> Enum.${enumFn}(${this.lambda(callback, ctx, true)})`
          }
          return `Enum.${enumFn}(${target()}, ${this.lambda(callback, ctx)})`
        }
        case "has": return `${this.expr(args[0], ctx)} in ${target()}`
        case "getFullYear": return `${target()}.year`
        case "getMonth": return `${target()}.month - 1`
        case "getDate": return `${target()}.day`
      }
    }
    throw new Unsupported(`call \`${name || "expression"}(...)\``)
  }

  /** `new Set(list)`, `new Map()`, `new Date()` / `new Date(y, m, d)`. */
  private construct(node: t.NewExpression, ctx: Ctx): string {
    const name = node.callee.type === "Identifier" ? node.callee.name : ""
    const args = node.arguments.map(argument => this.expr(argument, ctx))
    if (name === "Set") return args.length ? `MapSet.new(${args[0]})` : "MapSet.new()"
    if (name === "Map" && !args.length) return "%{}"
    if (name === "Date" && !args.length) return "Date.utc_today()"
    if (name === "Date" && args.length >= 3) {
      const month = node.arguments[1].type === "NumericLiteral" ? String(Number(args[1]) + 1) : `${args[1]} + 1`
      return `Date.new!(${args[0]}, ${month}, ${args[2]})`
    }
    throw new Unsupported(`\`new ${name || "expression"}(...)\``)
  }

  private lambda(node: t.Expression, ctx: Ctx, withIndex = false): string {
    if ((node.type !== "ArrowFunctionExpression" && node.type !== "FunctionExpression") || node.body.type === "BlockStatement") throw new Unsupported("callback with a block body")
    const inner: Ctx = { ...ctx, scope: new Map(ctx.scope) }
    const params = node.params.map(param => this.loopParam(param, inner))
    return `fn ${withIndex ? `{${params.join(", ")}}` : params.join(", ")} -> ${this.expr(node.body, inner)} end`
  }

  private loopParam(param: t.Node, ctx: Ctx, fallback = "item"): string {
    if (param.type === "Identifier") {
      const name = elixirVar(param.name)
      ctx.scope.set(param.name, { b: "code", code: name })
      return name
    }
    if (param.type === "ObjectPattern") {
      const name = ctx.scope.has(fallback) ? `${fallback}_${ctx.loopIndexes.length + 1}` : fallback
      for (const property of param.properties) {
        if (property.type !== "ObjectProperty" || property.key.type !== "Identifier") continue
        const local = property.value.type === "Identifier" ? property.value.name : property.key.name
        const code = atomAccess(name, elixirVar(property.key.name))
        ctx.scope.set(local, /^[A-Z]/.test(local) ? { b: "icon", code } : { b: "code", code })
      }
      return name
    }
    return "_"
  }

  // ---------------------------------------------------------------- data constants

  /**
   * Data function name for a binding: the binding itself (`chartData` → `chart_data`), qualified by its file when the
   * binding is a generic `data` (`data` in app-sidebar.tsx → `sidebar_data`) or the name is taken
   * (`chartData` in data-table.tsx → `data_table_chart_data`).
   */
  private dataFnName(file: string, base: string): string {
    const taken = new Set([...this.consts.values()].map(other => other.fn))
    const free = (fn: string) => !reservedFunctions[fn] && !reserved[fn] && !this.meta.functions.has(fn) && !taken.has(fn)
    const stem = elixirVar(file.split("/").pop()!.replace(/\.\w+$/, "")).replace(/^app_(?=\w)/, "")
    const qualified = ["page", "index", base].includes(stem) || base.startsWith(`${stem}_`) ? base : `${stem}_${base}`
    if (base === "data" && free(qualified)) return qualified
    if (free(base)) return base
    if (free(qualified)) return qualified
    for (let n = 2; ; n++) if (free(`${qualified}_${n}`)) return `${qualified}_${n}`
  }

  private registerConst(parsed: ParsedFile, name: string, node: t.Expression, prefix?: string): string {
    const key = `${parsed.file}#${prefix ? `${prefix}.` : ""}${name}`
    let constant = this.consts.get(key)
    if (!constant) {
      const fn = this.dataFnName(parsed.file, prefix ? `${prefix}_${elixirVar(name)}` : elixirVar(name))
      constant = { fn, line: lineOf(node), file: parsed.file, used: false, missingIcons: [], node }
      const unit = this.dataUnit(parsed)
      try {
        constant.term = this.term(node, { unit, scope: new Map(), contexts: new Map(), loopIndexes: [] }, undefined, constant.missingIcons)
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        constant.error = error.message
      }
      this.consts.set(key, constant)
    }
    return key
  }

  /** `import data from "./data.json"` (or a named import of one key): the JSON as a data function. */
  private registerJson(file: string, local: string, imported: string): string {
    const key = `${file}#json:${imported}`
    if (this.consts.has(key)) return key
    const fn = this.dataFnName(file, elixirVar(local))
    const constant: DataConst = { fn, line: 1, file, used: false, missingIcons: [] }
    const toTerm = (value: unknown): Term => {
      if (Array.isArray(value)) return { t: "list", items: value.map(toTerm) }
      if (value && typeof value === "object") return { t: "map", entries: Object.entries(value).map(([name, item]): [string, Term] => [/^[A-Za-z_]\w*$/.test(name) ? elixirVar(name) : name, toTerm(item)]) }
      if (typeof value === "string") return { t: "raw", code: elixirString(value) }
      if (typeof value === "number" && !Number.isFinite(value)) throw new Unsupported("non-finite number in JSON")
      return { t: "raw", code: value === null ? "nil" : String(value) }
    }
    try {
      const json: unknown = JSON.parse(this.set.files.get(file)!)
      const value = imported === "default" || imported === "*" ? json : (json as Record<string, unknown> | null)?.[imported]
      if (value === undefined) throw new Unsupported(`\`${imported}\` is not a key of ${file.split("/").pop()}`)
      constant.term = toTerm(value)
    } catch (error) {
      if (!(error instanceof Unsupported) && !(error instanceof SyntaxError)) throw error
      constant.error = error.message
    }
    this.consts.set(key, constant)
    return key
  }

  /** Pseudo unit for module-level data: resolves the file's imports, never needs attrs. */
  private dataUnit(parsed: ParsedFile): Unit {
    const node = { type: "ArrowFunctionExpression", params: [], body: { type: "NullLiteral" } } as unknown as ComponentDecl["node"]
    return {
      key: `${parsed.file}#data`, decl: { name: "Data", file: parsed.file, node, exported: false, isDefault: false }, parsed, fnName: "",
      entry: true, props: new Map(), needs: new Map(), restInclude: new Set(), hasRest: false, hasChildren: false, callSites: [], heex: "", keyed: false, consumedProps: new Set(),
    }
  }

  private constRef(key: string): string {
    const constant = this.consts.get(key)!
    if (constant.error) throw new Unsupported(`constant \`${constant.fn}\` is not plain data (${constant.error})`)
    if (!constant.used) {
      for (const missing of constant.missingIcons) {
        this.todos.push({ file: constant.file, line: missing.line, reason: `Lucide icon \`${missing.name}\` in \`${constant.fn}()\` is not supported by icon/1 and no lucide-react package was found for an inline SVG (set to nil, so it renders nothing); choose a supported name or pass --lucide`, rule: rules.icons })
      }
    }
    constant.used = true
    return `${constant.fn}()`
  }

  private term(node: t.Expression | t.Node, ctx: Ctx, key: string | undefined, missing: { name: string; line: number }[]): Term {
    const value = unwrap(node as t.Expression)
    if (value.type === "ObjectExpression") {
      const entries: [string, Term][] = []
      for (const property of value.properties) {
        if (property.type !== "ObjectProperty") throw new Unsupported("object spread/method in data")
        const rawKey = property.key.type === "Identifier" ? property.key.name : property.key.type === "StringLiteral" ? property.key.value : property.key.type === "NumericLiteral" ? String(property.key.value) : undefined
        if (rawKey === undefined || property.computed) throw new Unsupported("computed key in data")
        const elixirKey = /^[A-Za-z_]\w*$/.test(rawKey) ? elixirVar(rawKey) : rawKey
        entries.push([elixirKey, this.term(property.value, ctx, elixirKey, missing)])
      }
      return { t: "map", entries }
    }
    if (value.type === "ArrayExpression") {
      return { t: "list", items: value.elements.map(element => {
        if (!element || element.type === "SpreadElement") throw new Unsupported("array spread in data")
        return this.term(element, ctx, undefined, missing)
      }) }
    }
    const component = isJsx(value) ? (value.type === "JSXElement" ? this.iconComponent(value, ctx) : undefined)
      : value.type === "Identifier" && /^[A-Z]/.test(value.name) && this.componentKind(value.name, ctx)?.kind === "lucide" ? this.importedName(value.name, ctx) : undefined
    if (component !== undefined) {
      if (key) this.iconKeys.add(key)
      const icon = component ? this.iconName(component) : undefined
      if (!icon) missing.push({ name: component || "(no lucide name)", line: lineOf(value) })
      return { t: "raw", code: icon ? elixirString(icon) : "nil" }
    }
    if (isJsx(value)) throw new Unsupported("JSX (other than an icon) inside data")
    return { t: "raw", code: this.expr(value, ctx) }
  }

  // ---------------------------------------------------------------- icons

  /** Lucide component name of an icon element; undefined if not an icon element; "" without a lucide name. */
  private iconComponent(node: t.JSXElement, ctx: Ctx): string | undefined {
    const name = jsxName(node.openingElement.name)
    const kind = this.componentKind(name, ctx)
    if (kind?.kind === "icon-placeholder") {
      const lucide = this.jsxAttr(node, "lucide")
      return lucide?.value?.type === "StringLiteral" ? lucide.value.value : ""
    }
    if (kind?.kind === "lucide") return this.importedName(name, ctx)
    return undefined
  }

  /** Name accepted by `icon/1`, or a Lucide name inlined as SVG by `template_icon/1`. */
  private iconName(component: string): string | undefined {
    const supported = lucideName(this.meta, component)
    if (supported) return supported
    const svg = this.opts.lucide?.svg(component)
    if (!svg) return undefined
    const kebabName = lucideKebab(component)
    this.inlineIcons.set(kebabName, svg)
    return kebabName
  }

  private iconNode(nameCode: string, attrs: HAttr[], dynamic: boolean): HElement {
    const literal = nameCode.match(/^"(.+)"$/)?.[1]
    const tag = literal ? (this.inlineIcons.has(literal) ? ".template_icon" : ".icon") : this.inlineIcons.size ? ".template_icon" : ".icon"
    const node = el(tag, [{ name: "name", value: literal ? `"${literal}"` : `{${nameCode}}` }, ...attrs])
    if (dynamic) node.attrs.unshift({ name: ":if", value: `{${nameCode}}` })
    return node
  }

  // ---------------------------------------------------------------- JSX children

  private children(children: t.JSXElement["children"], ctx: Ctx): HNode[] {
    const result: HNode[] = []
    for (const child of children) {
      if (child.type === "JSXText") {
        const text = cleanJsxText(child.value)
        if (text) result.push({ k: "text", v: text })
      } else if (child.type === "JSXExpressionContainer") {
        if (child.expression.type === "JSXEmptyExpression") {
          for (const comment of child.expression.innerComments ?? []) result.push({ k: "comment", v: stripCodeForComment(comment.value) })
        } else {
          result.push(...this.child(child.expression, ctx))
        }
      } else if (child.type === "JSXSpreadChild") {
        result.push(this.todo(ctx, child, "JSX spread child"))
      } else {
        result.push(...this.child(child, ctx))
      }
    }
    return result
  }

  child(node: t.Expression | t.JSXElement | t.JSXFragment, ctx: Ctx): HNode[] {
    const value = unwrap(node as t.Expression)
    this.visited.add(node).add(value)
    try {
      switch (value.type) {
        case "JSXElement": return this.element(value, ctx)
        case "JSXFragment": return this.children(value.children, ctx)
        case "StringLiteral": return value.value ? [{ k: "text", v: value.value }] : []
        case "NumericLiteral": return [{ k: "text", v: String(value.value) }]
        case "NullLiteral": case "BooleanLiteral": return []
        case "LogicalExpression":
          if (value.operator === "&&" && containsJsx(value.right)) {
            const cond = this.condition(value.left, ctx)
            if (cond === "false") return this.accounted.add(value.right) && []
            const inner = this.child(value.right, ctx)
            return cond === "true" ? inner : this.wrapIf(inner, cond)
          }
          break
        case "ConditionalExpression":
          if (containsJsx(value.consequent) || containsJsx(value.alternate)) {
            const cond = this.condition(value.test, ctx)
            if (cond === "true") return this.accounted.add(value.alternate) && this.child(value.consequent, ctx)
            if (cond === "false") return this.accounted.add(value.consequent) && this.child(value.alternate, ctx)
            return this.ifElse(cond, this.child(value.consequent, ctx), this.child(value.alternate, ctx))
          }
          break
        case "CallExpression": case "OptionalCallExpression":
          if ((value.callee.type === "MemberExpression" || value.callee.type === "OptionalMemberExpression") && value.callee.property.type === "Identifier" && value.callee.property.name === "map") {
            return this.loop(value, ctx)
          }
          break
        case "Identifier": {
          const binding = this.lookup(value.name, ctx)
          if (binding?.b === "children") return [{ k: "expr", code: "render_slot(@inner_block)" }]
          if (binding?.b === "local" && containsJsx(binding.node)) return this.child(binding.node as t.Expression, { ...binding.ctx, unit: ctx.unit, contexts: ctx.contexts, loopIndexes: ctx.loopIndexes })
          if (binding?.b === "icon") return [this.iconNode(binding.code, [], false)]
          break
        }
        case "MemberExpression": case "OptionalMemberExpression": {
          const resolved = this.staticMember(value, ctx)
          if (resolved) return this.child(resolved.node, resolved.ctx)
          if (value.property.type === "Identifier" && this.iconKeys.has(elixirVar(value.property.name))) {
            return [this.iconNode(this.expr(value, ctx), [], true)]
          }
          if (value.property.type === "Identifier" && value.property.name === "children" && value.object.type === "Identifier" && value.object.name === ctx.unit.propsParam) {
            ctx.unit.hasChildren = true
            return [{ k: "expr", code: "render_slot(@inner_block)" }]
          }
          break
        }
      }
      if (containsJsx(value)) throw new Unsupported("JSX inside this expression")
      return [{ k: "expr", code: this.expr(value, ctx) }]
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      return [this.todo(ctx, value, `${error.message}: \`${this.snippet(value, ctx)}\``)]
    }
  }

  /** Plain text content of an element (for derived `value`s), or undefined if it has markup. */
  private staticText(node: t.JSXElement, ctx: Ctx): string | undefined {
    const parts: string[] = []
    for (const child of node.children) {
      if (child.type === "JSXText") parts.push(cleanJsxText(child.value))
      else if (child.type === "JSXExpressionContainer" && child.expression.type === "StringLiteral") parts.push(child.expression.value)
      else if (child.type === "JSXElement" && this.iconComponent(child, ctx) !== undefined) continue
      else return undefined
    }
    const text = parts.join("").trim()
    return text || undefined
  }

  /** Whether an expression is known to be a string (literal, template, or a string constant). */
  private isString(node: t.Node, ctx: Ctx): boolean {
    const value = unwrap(node as t.Expression)
    if (value.type === "StringLiteral" || value.type === "TemplateLiteral") return true
    if (value.type !== "Identifier") return false
    const binding = this.lookup(value.name, ctx)
    if (binding?.b === "code" && binding.string) return true
    if (binding?.b === "local") return this.isString(binding.node, binding.ctx)
    if (binding?.b === "const") return this.consts.get(binding.key)?.term?.t === "raw" && this.consts.get(binding.key)!.term!.code.startsWith('"')
    return false
  }

  private snippet(node: t.Node, ctx: Ctx): string {
    const text = ctx.unit.parsed.code.slice(node.start ?? 0, node.end ?? 0).replace(/\s+/g, " ")
    return text.length > 80 ? `${text.slice(0, 77)}...` : text
  }

  private wrapIf(nodes: HNode[], cond: string): HNode[] {
    if (nodes.length === 1 && nodes[0].k === "el" && !nodes[0].tag.startsWith(":") && !nodes[0].attrs.some(attr => attr.name === ":if" || attr.name === ":for")) {
      nodes[0].attrs.unshift({ name: ":if", value: `{${cond}}` })
      return nodes
    }
    if (!nodes.length) return []
    return [{ k: "if", cond, then: nodes, else: [] }]
  }

  private ifElse(cond: string, then: HNode[], otherwise: HNode[]): HNode[] {
    // `:if` only needs truthiness, so the inverse of `!x` is `x` (not `!(!x)`).
    const inverse = /^![@\w.()\[\]:"]+$/.test(cond) ? cond.slice(1) : negate(cond)
    if (!otherwise.length) return this.wrapIf(then, cond)
    if (!then.length) return this.wrapIf(otherwise, inverse)
    const single = (nodes: HNode[]) => nodes.length === 1 && nodes[0].k === "el" && !nodes[0].attrs.some(attr => attr.name === ":if" || attr.name === ":for")
    if (single(then) && single(otherwise)) return [...this.wrapIf(then, cond), ...this.wrapIf(otherwise, inverse)]
    return [{ k: "if", cond, then, else: otherwise }]
  }

  private loop(node: t.CallExpression | t.OptionalCallExpression, ctx: Ctx): HNode[] {
    const callee = node.callee
    if (callee.type !== "MemberExpression" && callee.type !== "OptionalMemberExpression") throw new Unsupported("`.map` on a computed callee")
    const callback = node.arguments[0]
    if (!callback || (callback.type !== "ArrowFunctionExpression" && callback.type !== "FunctionExpression")) throw new Unsupported("`.map` without an inline callback")
    const literal = this.literalArray(callee.object, ctx)
    if (literal) return this.unroll(literal, callback, ctx)
    const optional = node.type === "OptionalCallExpression" || callee.optional
    const list = optional ? `${this.expr(callee.object, ctx)} || []` : this.expr(callee.object, ctx)
    const inner: Ctx = { ...ctx, scope: new Map(ctx.scope), loopIndexes: [...ctx.loopIndexes] }
    const item = callback.params[0] ? this.loopParam(callback.params[0], inner) : "_item"
    let index = callback.params[1]?.type === "Identifier" ? elixirVar(callback.params[1].name) : undefined
    if (callback.params[1]?.type === "Identifier") inner.scope.set(callback.params[1].name, { b: "code", code: index! })
    if (!index && this.needsIndex(callback.body, ctx)) index = ctx.loopIndexes.length ? `index_${ctx.loopIndexes.length + 1}` : "index"
    if (index) inner.loopIndexes.push(index)
    const param = callback.params[0]
    if (param?.type === "Identifier") inner.scope.set(param.name, { b: "code", code: item, item: { list: callee.object as t.Expression, ctx, index } })
    const body = this.callbackBody(callback, inner)
    const nodes = this.child(body, inner)
    const gen = index ? `{${item}, ${index}} <- Enum.with_index(${list})` : `${item} <- ${list}`
    if (nodes.length === 1 && nodes[0].k === "el" && !nodes[0].tag.startsWith(":") && !nodes[0].attrs.some(attr => attr.name === ":for")) {
      nodes[0].attrs.unshift({ name: ":for", value: `{${gen}}` })
      return nodes
    }
    if (nodes.length === 1 && nodes[0].k === "el" && nodes[0].tag.startsWith(":") && !nodes[0].attrs.some(attr => attr.name === ":for" || attr.name === ":if")) {
      nodes[0].attrs.unshift({ name: ":for", value: `{${gen}}` })
      return nodes
    }
    return [{ k: "for", gen, body: nodes }]
  }

  private callbackBody(callback: t.ArrowFunctionExpression | t.FunctionExpression, inner: Ctx): t.Expression {
    if (callback.body.type !== "BlockStatement") return callback.body
    for (const statement of callback.body.body) {
      if (statement.type === "ReturnStatement" && statement.argument) return statement.argument
      if (statement.type === "VariableDeclaration") for (const declarator of statement.declarations) this.localDeclaration(declarator, inner)
      else throw new Unsupported("`.map` callback with statements other than `const`")
    }
    throw new Unsupported("`.map` callback without a returned element")
  }

  /** A literal array (inline or a local/module constant) that holds JSX and so cannot become data. */
  private literalArray(node: t.Node, ctx: Ctx): t.ArrayExpression | undefined {
    const value = unwrap(node as t.Expression)
    let candidate: t.Node | undefined = value
    if (value.type === "Identifier") {
      const binding = this.lookup(value.name, ctx)
      if (binding?.b === "local") candidate = unwrap(binding.node)
      else if (binding?.b === "const" && this.consts.get(binding.key)?.error) candidate = ctx.unit.parsed.consts.get(value.name)
      else candidate = undefined
    }
    if (candidate?.type !== "ArrayExpression") return undefined
    let jsx = false
    const visit = (current: unknown): void => {
      if (jsx || !current || typeof current !== "object") return
      if (Array.isArray(current)) return current.forEach(visit)
      if ("type" in current && (current.type === "JSXElement" || current.type === "JSXFragment")) jsx = true
      else for (const [key, child] of Object.entries(current)) if (key !== "loc" && key !== "leadingComments" && key !== "trailingComments") visit(child)
    }
    visit(candidate)
    return jsx ? candidate : undefined
  }

  /** `items.map(...)` over a literal array holding JSX: render each element at conversion time. */
  private unroll(array: t.ArrayExpression, callback: t.ArrowFunctionExpression | t.FunctionExpression, ctx: Ctx): HNode[] {
    const nodes: HNode[] = []
    array.elements.forEach((element, index) => {
      if (!element || element.type === "SpreadElement") throw new Unsupported("spread in a literal array")
      const inner: Ctx = { ...ctx, scope: new Map(ctx.scope) }
      const [param, indexParam] = callback.params
      if (param?.type === "Identifier") inner.scope.set(param.name, { b: "local", node: element, ctx })
      else if (param?.type === "ObjectPattern" && element.type === "ObjectExpression") {
        for (const property of param.properties) {
          if (property.type !== "ObjectProperty" || property.key.type !== "Identifier") continue
          const local = property.value.type === "Identifier" ? property.value.name : property.key.name
          const keyName = property.key.name
          const found = element.properties.find(entry => entry.type === "ObjectProperty" && entry.key.type === "Identifier" && entry.key.name === keyName)
          inner.scope.set(local, found?.type === "ObjectProperty" ? { b: "local", node: found.value as t.Expression, ctx } : { b: "code", code: "nil" })
        }
      }
      if (indexParam?.type === "Identifier") inner.scope.set(indexParam.name, { b: "code", code: String(index) })
      nodes.push(...this.child(this.callbackBody(callback, inner), inner))
    })
    this.note(ctx, array, "a literal array holding JSX was unrolled at conversion time (one copy of the markup per item).")
    return nodes
  }

  /** `item.content` where `item` is a literal object binding: the property's own expression node. */
  private staticMember(node: t.MemberExpression | t.OptionalMemberExpression, ctx: Ctx): { node: t.Expression; ctx: Ctx } | undefined {
    if (node.computed || node.property.type !== "Identifier") return undefined
    const name = node.property.name
    let object: t.Expression | undefined
    let objectCtx = ctx
    if (node.object.type === "Identifier") {
      const binding = ctx.scope.get(node.object.name)
      if (binding?.b !== "local") return undefined
      object = unwrap(binding.node)
      objectCtx = binding.ctx
    } else if (node.object.type === "MemberExpression" || node.object.type === "OptionalMemberExpression") {
      const parent = this.staticMember(node.object, ctx)
      if (!parent) return undefined
      object = unwrap(parent.node)
      objectCtx = parent.ctx
    }
    if (object?.type !== "ObjectExpression") return undefined
    const property = object.properties.find(entry => entry.type === "ObjectProperty" && !entry.computed && ((entry.key.type === "Identifier" && entry.key.name === name) || (entry.key.type === "StringLiteral" && entry.key.value === name)))
    if (property?.type !== "ObjectProperty") return { node: { type: "NullLiteral" } as t.NullLiteral, ctx: objectCtx }
    return { node: property.value as t.Expression, ctx: { ...objectCtx, unit: ctx.unit, contexts: ctx.contexts, loopIndexes: ctx.loopIndexes } }
  }

  /** True when a loop body renders a stateful family root, whose ids must then differ per item. */
  private needsIndex(body: t.Node, ctx: Ctx): boolean {
    let found = false
    const visit = (node: t.Node | null | undefined): void => {
      if (!node || found || typeof node !== "object") return
      if (node.type === "JSXOpeningElement") {
        const name = jsxName(node.name)
        const kind = this.componentKind(name, ctx)
        if (kind?.kind === "ui") {
          const fn = toSnakeCase(this.importedName(name, ctx))
          if (popupFamilies[fn] || modalFamilies[fn] || fn === "select" || this.meta.functions.get(fn)?.attrs.get("id")?.required) found = true
        }
      }
      for (const key of Object.keys(node) as (keyof typeof node)[]) {
        if (key === "loc" || key === "leadingComments" || key === "trailingComments") continue
        const value = node[key] as unknown
        if (Array.isArray(value)) value.forEach(entry => visit(entry as t.Node))
        else if (value && typeof value === "object" && "type" in (value as object)) visit(value as t.Node)
      }
    }
    visit(body)
    return found
  }

  // ---------------------------------------------------------------- JSX elements

  private importedName(name: string, ctx: Ctx): string {
    const imported = ctx.unit.parsed.imports.get(name)
    return imported && imported.imported !== "default" && imported.imported !== "*" ? imported.imported : name
  }

  private componentKind(name: string, ctx: Ctx): ImportKind | { kind: "same-file" } | undefined {
    const parsed = ctx.unit.parsed ?? this.file(ctx.unit.decl.file)
    if (parsed.components.has(name)) return { kind: "same-file" }
    const imported = parsed.imports.get(name.split(".")[0])
    if (!imported) return undefined
    return classifyImport(this.set, parsed.file, imported.source, imported.imported)
  }

  private element(node: t.JSXElement, ctx: Ctx): HNode[] {
    this.visited.add(node)
    const replaced = ctx.replace?.get(node)
    if (replaced) return replaced
    const part = this.tableParts.get(node)
    if (part) return this.tablePart(node, part, ctx)
    const tableProp = this.jsxAttrExpr(node, "table")
    const table = tableProp?.type === "Identifier" ? this.lookup(tableProp.name, ctx) : undefined
    if (table?.b === "table") {
      // shadcn's data-table guide components (`<DataTablePagination table={table} />`, `<DataTableViewOptions .../>`).
      const kind = /Pagination$/.test(jsxName(node.openingElement.name)) ? "pagination" : /ViewOptions$/.test(jsxName(node.openingElement.name)) ? "columns" : undefined
      const decl = ctx.unit.parsed.components.get(jsxName(node.openingElement.name))
      if (decl) this.accounted.add(decl.node)
      if (kind) return this.tablePart(node, { kind, spec: table.spec }, ctx)
    }
    const name = jsxName(node.openingElement.name)
    if (name === "React.Fragment" || name === "Fragment") return this.children(node.children, ctx)
    if (/^[a-z]/.test(name) && !name.includes(".")) return this.html(node, name, ctx)
    if (transparentComponents[name]) return this.children(node.children, ctx)
    if (name.includes(".")) {
      // `<item.icon />` where `icon` holds a component from data.
      const [object, ...rest] = name.split(".")
      const property = rest.join(".")
      if (this.lookup(object, ctx) && this.iconKeys.has(elixirVar(property))) {
        const code = atomAccess(this.expr({ type: "Identifier", name: object } as t.Identifier, ctx), elixirVar(property))
        return [this.iconNode(code, this.plainAttrs(node, ctx, this.meta.functions.get("icon")!), false)]
      }
    }
    const binding = this.lookup(name, ctx)
    if (binding?.b === "icon") return [this.iconNode(binding.code, this.plainAttrs(node, ctx, this.meta.functions.get("icon")!), false)]
    const kind = this.componentKind(name, ctx)
    switch (kind?.kind) {
      case "ui": return this.ui(node, this.importedName(name, ctx), kind.family, ctx)
      case "icon-placeholder": case "lucide": {
        const component = this.iconComponent(node, ctx) ?? ""
        const icon = component ? this.iconName(component) : undefined
        if (!icon) return [this.todo(ctx, node, `Lucide icon \`${component || this.snippet(node.openingElement, ctx)}\` is not supported by icon/1 and no lucide-react package was found for an inline SVG; choose a supported name (usage-rules/components.md#icons), paste the SVG or pass --lucide`, rules.icons)]
        this.mapped(name, "icon")
        return [this.iconNode(elixirString(icon), this.plainAttrs(node, ctx, this.meta.functions.get("icon")!), false)]
      }
      case "icon-other": return [this.todo(ctx, node, `icon from \`${kind.source}\`; use a Lucide name supported by icon/1 or an inline SVG`, rules.icons)]
      case "same-file": return this.local(node, ctx.unit.parsed.components.get(name)!, ctx)
      case "local": {
        const other = this.file(kind.file)
        const imported = ctx.unit.parsed.imports.get(name)!
        const decl = imported.imported === "default" ? other.components.get(other.defaultExport ?? "") : other.components.get(imported.imported)
        if (decl) return this.local(node, decl, ctx)
        return [this.todo(ctx, node, `\`${name}\` from ${kind.file} is not a convertible component`), ...this.children(node.children, ctx)]
      }
      case "next-link": {
        this.mapped(name, "link")
        const attrs = this.plainAttrs(node, ctx, undefined).map(attr => (attr.name === "href" ? { name: attr.value?.startsWith('"/') ? "navigate" : "href", value: attr.value } : attr))
        return [el(".link", attrs, this.children(node.children, ctx))]
      }
      case "next-image": {
        this.mapped(name, "img")
        return [el("img", this.plainAttrs(node, ctx, undefined).filter(attr => attr.name !== "priority" && attr.name !== "fill"))]
      }
      case "sonner":
        if (name === "Toaster") {
          this.toasterRendered = true
          this.mapped(name, "toaster")
          return [el(".toaster", [{ name: "id", value: '"toaster"' }])]
        }
    }
    if (kind?.kind === "unknown" && kind.source === "recharts") {
      // Its children (<defs>, axes, series) mean nothing outside the chart: never emit them on their own.
      return [this.todo(ctx, node, `Recharts \`<${name}>\` outside a convertible ChartContainer chart (source lines ${lineOf(node)}-${node.loc?.end.line ?? lineOf(node)} omitted); rebuild it with chart_container/chart_canvas`, `${rules.components} (\`chart\` row)`)]
    }
    return [this.todo(ctx, node, `\`<${name}>\` is not a shadcn/ui component, icon or local component the converter can resolve`), ...this.children(node.children, ctx)]
  }

  /** Attributes of an HTML element (or a component with HTML-ish props). */
  private plainAttrs(node: t.JSXElement, ctx: Ctx, fn: FnMeta | undefined, skip: Record<string, true> = {}): HAttr[] {
    const attrs: HAttr[] = []
    for (const attribute of node.openingElement.attributes) {
      if (attribute.type === "JSXSpreadAttribute") {
        const spread = this.spread(attribute, ctx)
        if (spread) attrs.push(spread)
        continue
      }
      const reactName = attribute.name.type === "JSXIdentifier" ? attribute.name.name : `${attribute.name.namespace.name}:${attribute.name.name.name}`
      if (skip[reactName] || ignoredProps[reactName] || (fn?.name === "icon" && iconProviderProps[reactName])) continue
      if (reactName === "ref") {
        this.note(ctx, attribute, "React `ref` dropped; use a phx-hook if the element needs client behavior.")
        continue
      }
      if (/^on[A-Z]/.test(reactName)) {
        attrs.push(...this.event(reactName, attribute, ctx, fn))
        continue
      }
      if (reactName === "dangerouslySetInnerHTML") {
        attrs.push({ name: "data-todo", value: '"inner-html"' })
        this.todo(ctx, attribute, "dangerouslySetInnerHTML; render trusted markup with Phoenix.HTML.raw/1 instead")
        continue
      }
      const htmlName = htmlAttrNames[reactName] ?? (svgCamelAttrs.test(reactName) ? reactName.replace(/([A-Z])/g, "-$1").toLowerCase() : reactName)
      let name = htmlName
      if (fn) {
        const candidates = [elixirVar(reactName), htmlName, reactName.toLowerCase()]
        if (fn.name === "sidebar_menu_button" && reactName === "tooltip") {
          // `tooltip="Inbox"` / `tooltip={{ children: "Inbox", hidden: false }}` → a native `title`, set only while the
          // desktop sidebar is collapsed (React shows the tooltip only then).
          const object = attribute.value?.type === "JSXExpressionContainer" ? unwrap(attribute.value.expression as t.Expression) : undefined
          const text = object?.type === "ObjectExpression"
            ? object.properties.find(entry => entry.type === "ObjectProperty" && entry.key.type === "Identifier" && entry.key.name === "children")
            : undefined
          try {
            const textNode = text?.type === "ObjectProperty" ? text.value : object?.type === "ObjectExpression" ? undefined : attribute.value?.type === "StringLiteral" ? attribute.value : object
            if (!textNode) continue
            const textCode = this.expr(textNode, ctx)
            let sidebar: string | undefined
            try {
              sidebar = this.contextRef(ctx, "sidebar", attribute)
            } catch (error) {
              if (!(error instanceof Unsupported)) throw error
            }
            attrs.push({ name: "title", value: codeAttr(sidebar ? `if(${sidebar}.open, do: nil, else: ${textCode})` : textCode) })
            this.note(ctx, attribute, `sidebar_menu_button has no tooltip; \`tooltip\` became a native \`title\`${sidebar ? " set only while the sidebar is collapsed" : ""} (browser tooltip delay/appearance).`)
          } catch (error) {
            if (!(error instanceof Unsupported)) throw error
            this.todo(ctx, attribute, `prop \`tooltip\`: ${error.message}; dropped`, rules.sidebar)
          }
          continue
        }
        const found = candidates.find(candidate => fn.attrs.has(candidate)) ?? candidates.find(candidate => acceptsAttr(fn, candidate))
        if (!found) {
          if (fn.name === "icon") this.note(ctx, attribute, `icon/1: React prop \`${reactName}\` dropped.`)
          else this.todo(ctx, attribute, `prop \`${reactName}\` is not an attr of ${fn.name}/1; dropped`, familyRule(fn.family))
          continue
        }
        name = found
      }
      try {
        if (name === "class") {
          attrs.push({ name, value: this.classValue(attribute.value, ctx) })
          continue
        }
        if (name === "style") {
          attrs.push({ name, value: this.styleValue(attribute.value, ctx) })
          continue
        }
        const value = this.attrValue(attribute.value, ctx)
        const allowed = fn?.attrs.get(name)?.values
        const literal = value?.match(/^"(.*)"$/)?.[1]
        if (fn && allowed && literal !== undefined && !allowed.includes(literal)) {
          this.todo(ctx, attribute, `${fn.name} ${name}="${literal}" is not one of ${allowed.join("/")}; dropped`, familyRule(fn.family))
          continue
        }
        attrs.push({ name, value })
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        this.todo(ctx, attribute, `prop \`${reactName}\`: ${error.message} (\`${this.snippet(attribute, ctx)}\`); dropped`)
      }
    }
    return attrs
  }

  private spread(attribute: t.JSXSpreadAttribute, ctx: Ctx): HAttr | undefined {
    const argument = attribute.argument
    if (argument.type === "Identifier") {
      const binding = this.lookup(argument.name, ctx)
      if (binding?.b === "rest") return { name: "{@rest}" }
      if (argument.name === ctx.unit.propsParam) {
        ctx.unit.hasRest = true
        return { name: "{@rest}" }
      }
    }
    this.todo(ctx, attribute, `spread \`{...${this.snippet(argument, ctx)}}\` dropped; pass the attributes explicitly`)
    return undefined
  }

  private attrValue(value: t.JSXAttribute["value"], ctx: Ctx): string | undefined {
    if (!value) return undefined
    if (value.type === "StringLiteral") return quoteAttr(value.value)
    if (value.type === "JSXExpressionContainer") {
      const expression = value.expression
      if (expression.type === "JSXEmptyExpression") return undefined
      const inner = unwrap(expression)
      if (inner.type === "StringLiteral") return quoteAttr(inner.value)
      if (inner.type === "BooleanLiteral" && inner.value) return undefined
      if (isJsx(inner)) throw new Unsupported("JSX as an attribute value")
      return `{${this.expr(inner, ctx)}}`
    }
    throw new Unsupported("JSX element as attribute value")
  }

  private classValue(value: t.JSXAttribute["value"], ctx: Ctx): string {
    if (!value) return '""'
    if (value.type === "StringLiteral") return quoteAttr(value.value)
    if (value.type !== "JSXExpressionContainer" || value.expression.type === "JSXEmptyExpression") return '""'
    const parts = this.classParts(value.expression, ctx)
    if (parts.length === 1 && codeAttr(parts[0]) === parts[0]) return parts[0]
    return parts.length === 1 ? `{${parts[0]}}` : `{[${parts.join(", ")}]}`
  }

  private classParts(node: t.Expression, ctx: Ctx): string[] {
    const value = unwrap(node)
    if (value.type === "CallExpression" && ["cn", "clsx", "twMerge", "cx"].includes(this.calleeName(value.callee))) {
      return value.arguments.flatMap(argument => {
        if (argument.type === "SpreadElement" || argument.type === "ArgumentPlaceholder") throw new Unsupported("spread in cn()")
        const inner = unwrap(argument as t.Expression)
        if (inner.type === "ObjectExpression") {
          return inner.properties.map(property => {
            if (property.type !== "ObjectProperty") throw new Unsupported("cn() object spread")
            const className = property.key.type === "StringLiteral" ? property.key.value : property.key.type === "Identifier" ? property.key.name : ""
            return `${this.condition(property.value as t.Expression, ctx)} && ${elixirString(className)}`
          })
        }
        if (inner.type === "ArrayExpression") return this.classParts(inner, ctx)
        return this.classParts(inner, ctx)
      })
    }
    if (value.type === "ArrayExpression") return value.elements.flatMap(element => (element && element.type !== "SpreadElement" ? this.classParts(element, ctx) : []))
    if (value.type === "LogicalExpression" && value.operator === "&&") return [`${this.condition(value.left, ctx)} && ${this.expr(value.right, ctx)}`]
    return [this.expr(value, ctx)]
  }

  private styleValue(value: t.JSXAttribute["value"], ctx: Ctx): string {
    if (!value || value.type === "StringLiteral") return value ? quoteAttr(value.value) : '""'
    if (value.type !== "JSXExpressionContainer" || value.expression.type === "JSXEmptyExpression") return '""'
    const object = unwrap(value.expression)
    if (object.type !== "ObjectExpression") return `{${this.expr(object, ctx)}}`
    const parts: string[] = []
    let dynamic = false
    const escape = (text: string) => text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/#\{/g, "\\#{")
    for (const property of object.properties) {
      if (property.type !== "ObjectProperty") throw new Unsupported("style spread")
      const key = property.key.type === "Identifier" ? property.key.name : property.key.type === "StringLiteral" ? property.key.value : ""
      const cssKey = key.startsWith("--") ? key : key.replace(/([A-Z])/g, "-$1").toLowerCase()
      const raw = unwrap(property.value as t.Expression)
      if (raw.type === "StringLiteral") parts.push(escape(`${cssKey}: ${raw.value}`))
      else if (raw.type === "NumericLiteral") parts.push(`${cssKey}: ${raw.value}${/^(opacity|z-index|flex|flex-grow|flex-shrink|order|font-weight|line-height)$/.test(cssKey) || cssKey.startsWith("--") ? "" : "px"}`)
      else {
        dynamic = true
        parts.push(`${escape(cssKey)}: #{${this.expr(raw, ctx)}}`)
      }
    }
    const text = parts.join("; ")
    return dynamic ? `{"${text}"}` : quoteAttr(text.replace(/\\(.)/g, "$1"))
  }

  private html(node: t.JSXElement, tag: string, ctx: Ctx): HNode[] {
    if (tag === "form" && this.hasFieldControls(node, ctx)) return this.form(node, ctx)
    const attrs = this.plainAttrs(node, ctx, undefined)
    return [el(tag, attrs, this.childrenOrRestSlot(node, attrs, ctx))]
  }

  /** `{...props}` on a childless element also forwards React's `props.children`. */
  private childrenOrRestSlot(node: t.JSXElement, attrs: HAttr[], ctx: Ctx): HNode[] {
    const children = this.children(node.children, ctx)
    if (children.length || node.children.some(child => child.type !== "JSXText" || child.value.trim()) || !attrs.some(attr => attr.name === "{@rest}")) return children
    ctx.unit.hasChildren = true
    return [{ k: "expr", code: "render_slot(@inner_block)" }]
  }

  // ---------------------------------------------------------------- events

  private event(reactName: string, attribute: t.JSXAttribute, ctx: Ctx, fn: FnMeta | undefined): HAttr[] {
    const value = attribute.value?.type === "JSXExpressionContainer" && attribute.value.expression.type !== "JSXEmptyExpression" ? unwrap(attribute.value.expression) : undefined
    if (!value) return []
    try {
      if (clickEvents[reactName] || (reactName === "onSubmit" && !fn)) {
        if (fn && !acceptsAttr(fn, "phx-click")) throw new Unsupported(`${fn.name}/1 accepts no phx-click`)
        const push = this.pushHandler(value, ctx)
        return [{ name: reactName === "onSubmit" ? "phx-submit" : "phx-click", value: `{${push}}` }]
      }
      throw new Unsupported(`\`${reactName}\` handler`)
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      this.todo(ctx, attribute, `${error.message} not converted: \`${this.snippet(value, ctx)}\`; add a phx-* binding and handle_event/3`, rules.state)
      return []
    }
  }

  /** `() => setX(expr)` (and blocks of setters / toast calls) → `JS.push(event, value: %{...})`. */
  private pushHandler(node: t.Expression, ctx: Ctx): string {
    if (node.type !== "ArrowFunctionExpression" && node.type !== "FunctionExpression") throw new Unsupported("handler that is not an inline arrow function")
    const statements: t.Expression[] = node.body.type === "BlockStatement"
      ? node.body.body.map(statement => {
        if (statement.type !== "ExpressionStatement") throw new Unsupported("handler with non-expression statements")
        return statement.expression
      })
      : [node.body]
    this.visited.add(node)
    const eventParam = node.params[0]?.type === "Identifier" ? node.params[0].name : undefined
    const sets: [string, string][] = []
    const lookups = new Map<string, Lookup>()
    let toast: string | undefined
    for (const statement of statements) {
      if (statement.type !== "CallExpression") throw new Unsupported("handler body")
      const callee = this.calleeName(statement.callee)
      if (eventParam && (callee === `${eventParam}.preventDefault` || callee === `${eventParam}.stopPropagation`)) continue
      const binding = statement.callee.type === "Identifier" ? this.lookup(statement.callee.name, ctx) : undefined
      if (binding?.b === "setter") {
        const argument = statement.arguments[0] as t.Expression | undefined
        if (argument && (argument.type === "ArrowFunctionExpression" || argument.type === "FunctionExpression")) {
          // setX((current) => !current)
          const param = argument.params[0]
          if (param?.type !== "Identifier" || argument.body.type === "BlockStatement") throw new Unsupported("state updater function")
          const inner = { ...ctx, scope: new Map(ctx.scope) }
          inner.scope.set(param.name, { b: "state", assign: binding.assign })
          sets.push([binding.assign, this.expr(argument.body, inner)])
        } else if (argument) {
          // A map from a list must not travel through JSON (atom keys come back as strings): push its key instead.
          const identity = this.identity(argument, ctx)
          if (identity) lookups.set(binding.assign, identity.lookup)
          sets.push([binding.assign, identity?.payload ?? this.expr(argument, ctx)])
        } else {
          sets.push([binding.assign, "nil"])
        }
        continue
      }
      if (/^toast(\.\w+)?$/.test(callee)) {
        const [message, options] = statement.arguments as t.Expression[]
        const entries = [`message: ${this.expr(message, ctx)}`]
        if (options?.type === "ObjectExpression") {
          for (const property of options.properties) {
            if (property.type === "ObjectProperty" && property.key.type === "Identifier" && property.key.name === "description") entries.push(`description: ${this.expr(property.value as t.Expression, ctx)}`)
          }
        }
        toast = `%{${entries.join(", ")}}`
        continue
      }
      throw new Unsupported(`call \`${callee || "expression"}\` in handler`)
    }
    this.usesJS = true
    if (toast && !sets.length) {
      this.toaster = true
      this.addClause("show_toast", "push", { body: 'push_event(socket, "shadcn:toast", %{toaster: "toaster", message: params["message"], description: params["description"]})', line: lineOf(node) })
      return `JS.push("show_toast", value: ${toast})`
    }
    if (toast) throw new Unsupported("handler mixing state updates and toast()")
    if (!sets.length) throw new Unsupported("empty handler")
    const event = `set_${sets.map(([assign]) => assign).join("_and_")}`
    this.addClause(event, "push", { assigns: sets.map(([assign]) => assign), line: lineOf(node), lookups })
    return `JS.push(${elixirString(event)}, value: %{${sets.map(([assign, code]) => `${assign}: ${code}`).join(", ")}})`
  }

  /**
   * `setTeam(team)` where `team` iterates a list of maps: the payload is the item's identifying key (or loop
   * index) and handle_event/3 looks the map up again in the list's server-side code.
   */
  private identity(argument: t.Expression, ctx: Ctx): { payload: string; lookup: Lookup } | undefined {
    const value = unwrap(argument)
    const binding = value.type === "Identifier" ? this.lookup(value.name, ctx) : undefined
    if (binding?.b !== "code" || !binding.item) {
      const term = this.resolveTerm(value, ctx)
      if (term?.t === "map" || term?.t === "list") throw new Unsupported("state set to a map/list literal (JSON turns its atom keys into strings); push an identifier and build the value in handle_event/3")
      return undefined
    }
    const { list, ctx: listCtx, index } = binding.item
    const term = this.resolveTerm(list, listCtx)
    if (!term) throw new Unsupported(`state set to an item of \`${this.snippet(list, listCtx)}\`, whose rows are not static data; push the row id and look the row up in handle_event/3`)
    if (term.t !== "list" || !term.items.some(item => item.t === "map")) return undefined
    const literal = (entry: Term | undefined) => (entry?.t === "raw" && /^(?:"(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?)$/.test(entry.code) ? entry.code : undefined)
    const key = identityKeys.find(candidate => {
      const codes = term.items.map(item => (item.t === "map" ? literal(item.entries.find(([name]) => name === candidate)?.[1]) : undefined))
      return codes.every(Boolean) && new Set(codes).size === codes.length
    })
    const file = ctx.unit.decl.file
    if (key) return { payload: atomAccess(binding.code, key), lookup: { list, ctx: listCtx, key, line: lineOf(argument), file } }
    if (index) return { payload: index, lookup: { list, ctx: listCtx, line: lineOf(argument), file } }
    throw new Unsupported(`state set to a map from \`${this.snippet(list, listCtx)}\` without a unique id/name key or loop index; push an identifier and look the row up in handle_event/3`)
  }

  /** Static data a React expression evaluates to (constants, JSON, props passed literal data), if known. */
  private resolveTerm(node: t.Node, ctx: Ctx, depth = 0): Term | undefined {
    const value = unwrap(node as t.Expression)
    if (depth > 8) return undefined
    if (value.type === "Identifier") {
      const binding = this.lookup(value.name, ctx)
      if (binding?.b === "const") return this.consts.get(binding.key)?.term
      if (binding?.b === "local") return this.resolveTerm(binding.node, binding.ctx, depth + 1)
      if (binding?.b !== "code") return undefined
      const prop = [...ctx.unit.props.values()].find(info => `@${info.attr}` === binding.code)
      const site = prop && ctx.unit.callSites.length === 1 ? ctx.unit.callSites[0].get(prop.attr) : undefined
      return site?.node ? this.resolveTerm(site.node, site.ctx, depth + 1) : undefined
    }
    if ((value.type === "MemberExpression" || value.type === "OptionalMemberExpression") && !value.computed && value.property.type === "Identifier") {
      const base = this.resolveTerm(value.object, ctx, depth + 1)
      const key = elixirVar(value.property.name)
      return base?.t === "map" ? base.entries.find(([name]) => name === key)?.[1] : undefined
    }
    if (value.type === "ObjectExpression" || value.type === "ArrayExpression") {
      try {
        return this.term(value, { ...ctx, scope: new Map(ctx.scope) }, undefined, [])
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
      }
    }
    return undefined
  }

  /** Setter passed to a family change prop (`onValueChange={setTab}` or `(v) => setTab(v)`). */
  private payloadSetter(node: t.Node | undefined, ctx: Ctx): string | undefined {
    if (!node) return undefined
    const value = unwrap(node as t.Expression)
    if (value.type === "Identifier") {
      const binding = this.lookup(value.name, ctx)
      if (binding?.b === "setter") return this.visited.add(value) && binding.assign
    }
    if ((value.type === "ArrowFunctionExpression" || value.type === "FunctionExpression") && value.params[0]?.type === "Identifier") {
      const param = value.params[0].name
      const body = value.body.type === "BlockStatement" && value.body.body.length === 1 && value.body.body[0].type === "ExpressionStatement" ? value.body.body[0].expression : value.body
      if (body.type === "CallExpression" && body.callee.type === "Identifier" && body.arguments.length === 1) {
        const binding = this.lookup(body.callee.name, ctx)
        const argument = unwrap(body.arguments[0] as t.Expression)
        if (binding?.b === "setter" && argument.type === "Identifier" && argument.name === param) return this.visited.add(value) && binding.assign
      }
    }
    return undefined
  }

  private addClause(event: string, style: ClauseStyle, extra: { assigns?: string[]; assign?: string; body?: string; uiKey?: string; line: number; lookups?: Map<string, Lookup>; keepValue?: boolean }): void {
    const existing = this.clauses.get(event)
    if (existing) {
      existing.styles.add(style)
      if (extra.keepValue) existing.keepValue = true
      return
    }
    this.clauses.set(event, { styles: new Set([style]), assign: extra.assign ?? extra.assigns?.join(","), body: extra.body, uiKey: extra.uiKey, line: extra.line, lookups: extra.lookups, keepValue: extra.keepValue })
  }

  // ---------------------------------------------------------------- local components

  private local(node: t.JSXElement, decl: ComponentDecl, ctx: Ctx): HNode[] {
    const unit = this.unitFor(decl)
    const attrs: HAttr[] = []
    const callSite = new Map<string, CallArg>()
    for (const attribute of node.openingElement.attributes) {
      if (attribute.type === "JSXSpreadAttribute") {
        const spread = this.spread(attribute, ctx)
        if (spread) {
          attrs.push(spread)
          unit.hasRest = true
        }
        continue
      }
      const reactName = attribute.name.type === "JSXIdentifier" ? attribute.name.name : ""
      if (!reactName || ignoredProps[reactName]) continue
      const prop = [...unit.props.entries()].find(([local, info]) => local === reactName || (info.attr === elixirVar(reactName) && info.attr !== "rest") || (reactName === "className" && info.attr === "class"))
      let name = prop?.[1].attr ?? (reactName === "className" ? "class" : htmlAttrNames[reactName] ?? elixirVar(reactName))
      if (/^on[A-Z]/.test(reactName)) {
        this.todo(ctx, attribute, `callback prop \`${reactName}\` on <${decl.name}>; LiveView sends events to the server instead`, rules.state)
        continue
      }
      const expression = attribute.value?.type === "JSXExpressionContainer" && attribute.value.expression.type !== "JSXEmptyExpression" ? attribute.value.expression : attribute.value?.type === "StringLiteral" ? attribute.value : undefined
      // Props the callee consumed at conversion time (TanStack `columns`/`data`): no attr, but the source stays resolvable.
      const consumed = !!prop && unit.consumedProps.has(prop[1].attr)
      try {
        const value = name === "class" ? this.classValue(attribute.value, ctx) : this.attrValue(attribute.value, ctx)
        if (!prop) {
          if (unit.propsParam) unit.props.set(`props.${reactName}`, { attr: name })
          else if (unit.hasRest) {
            name = htmlAttrNames[reactName] ?? reactName
            if (!isGlobalAttr(name)) unit.restInclude.add(name)
          } else {
            this.todo(ctx, attribute, `<${decl.name}> has no prop \`${reactName}\`; dropped`)
            continue
          }
        }
        if (!consumed) attrs.push({ name, value })
        callSite.set(name, { code: value === undefined ? "true" : value.startsWith("{") ? value.slice(1, -1) : JSON.stringify(value.slice(1, -1)), node: expression, ctx })
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        if (!consumed) this.todo(ctx, attribute, `prop \`${reactName}\` on <${decl.name}>: ${error.message}`)
        if (prop) callSite.set(prop[1].attr, { code: "", node: expression, ctx })
      }
    }
    for (const need of unit.needs.values()) {
      try {
        attrs.push({ name: need.attr, value: `{${need.kind === "assign" ? this.assignRef(ctx, need.attr) : this.contextRef(ctx, need.attr, node)}}` })
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        return [this.todo(ctx, node, `<${decl.name}> ${error.message}; the call was left out`, rules.state)]
      }
    }
    const suffix = this.keySuffix(ctx)
    if (suffix) {
      unit.keyed = true
      attrs.push({ name: "item_key", value: `{"${suffix.slice(1)}"}` })
    }
    unit.callSites.push(callSite)
    const children = this.children(node.children, ctx)
    if (children.length) unit.hasChildren = true
    this.mapped(decl.name, unit.fnName)
    return [el(`.${unit.fnName}`, attrs, children)]
  }

  // ---------------------------------------------------------------- shadcn/ui components

  private jsxAttr(node: t.JSXElement, name: string): t.JSXAttribute | undefined {
    return node.openingElement.attributes.find((attr): attr is t.JSXAttribute => attr.type === "JSXAttribute" && attr.name.name === name)
  }

  private jsxAttrExpr(node: t.JSXElement, name: string): t.Expression | undefined {
    const attr = this.jsxAttr(node, name)
    if (!attr?.value) return attr ? ({ type: "BooleanLiteral", value: true } as t.BooleanLiteral) : undefined
    if (attr.value.type === "StringLiteral") return attr.value
    if (attr.value.type === "JSXExpressionContainer" && attr.value.expression.type !== "JSXEmptyExpression") return attr.value.expression
    return undefined
  }

  private elementChildren(node: t.JSXElement | t.JSXFragment): t.JSXElement[] {
    return node.children.filter((child): child is t.JSXElement => child.type === "JSXElement")
  }

  /** Child JSX elements, including those behind `cond && <X/>` / ternaries in expression containers. */
  private jsxChildren(node: t.JSXElement | t.JSXFragment): t.JSXElement[] {
    const result: t.JSXElement[] = []
    const fromExpression = (expression: t.Node | null | undefined): void => {
      if (!expression) return
      if (expression.type === "JSXElement") result.push(expression)
      else if (expression.type === "JSXFragment") result.push(...this.jsxChildren(expression))
      else if (expression.type === "ConditionalExpression") [expression.consequent, expression.alternate].forEach(fromExpression)
      else if (expression.type === "LogicalExpression") fromExpression(expression.right)
      else if (expression.type === "ParenthesizedExpression") fromExpression(expression.expression)
    }
    for (const child of node.children) {
      if (child.type === "JSXElement") result.push(child)
      else if (child.type === "JSXFragment") result.push(...this.jsxChildren(child))
      else if (child.type === "JSXExpressionContainer" && child.expression.type !== "JSXEmptyExpression") fromExpression(child.expression)
    }
    return result
  }

  /** First descendant named `name` (e.g. `DropdownMenuTrigger`), not crossing a nested root of the same family. */
  private findPart(root: t.JSXElement, ctx: Ctx, name: string): t.JSXElement | undefined {
    const rootName = this.importedName(jsxName(root.openingElement.name), ctx)
    const queue = this.jsxChildren(root)
    while (queue.length) {
      const child = queue.shift()!
      const childName = this.importedName(jsxName(child.openingElement.name), ctx)
      if (childName === name) return child
      if (childName !== rootName) queue.push(...this.jsxChildren(child))
    }
    return undefined
  }

  /** True when the root's only element children are the given parts (no wrapper markup to keep). */
  private onlyParts(root: t.JSXElement, parts: (t.JSXElement | undefined)[]): boolean {
    const children = root.children.filter(child => child.type !== "JSXText" || child.value.trim())
    return children.every(child => child.type === "JSXElement" && parts.includes(child))
  }

  private ui(node: t.JSXElement, reactName: string, family: string, ctx: Ctx): HNode[] {
    const fnName = toSnakeCase(reactName)
    this.families.add(family)
    try {
      if (popupFamilies[fnName]) return this.popup(node, fnName, ctx)
      if (modalFamilies[fnName]) return this.modal(node, fnName, ctx)
      if (fnName === "select") return this.select(node, ctx)
      if (fnName === "chart_container" && this.meta.functions.has("chart_canvas")) return this.chart(node, reactName, ctx)
      if (/^(dropdown_menu|context_menu)_sub$/.test(fnName)) return this.flattenSubmenu(node, fnName, ctx)
      if (this.jsxAttr(node, "asChild")) {
        const modalFamily = fnName.match(/^(dialog|alert_dialog|sheet|drawer)_(close|action|cancel)$/)?.[1]
        if (modalFamily) return this.modalClose(node, modalFamily, reactName, ctx)
        if (fnName === "collapsible_trigger") return this.collapsibleTrigger(node, reactName, ctx)
        if (fnName === "collapsible") return this.collapsibleAsChild(node, reactName, ctx)
      }
      const fn = this.meta.functions.get(fnName)
      if (!fn) {
        return [this.todo(ctx, node, `\`<${reactName}>\` has no shadcn_liveview function (${fnName}/1)`, familyRule(family)), ...this.children(node.children, ctx)]
      }
      return this.generic(node, fn, reactName, ctx)
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      // Children of a failed context-providing root would reference a context that does not exist.
      const skip = error instanceof Skip || !!yieldingRoots[fnName] || !!popupFamilies[fnName] || !!modalFamilies[fnName] || fnName === "select"
      const children = skip ? [] : this.children(node.children, ctx)
      return [this.todo(ctx, node, `<${reactName}>: ${error.message}${skip ? ` (source lines ${lineOf(node)}-${node.loc?.end.line ?? lineOf(node)} omitted)` : ""}`, familyRule(family)), ...children]
    }
  }

  /**
   * `Collapsible asChild` around one element (`<SidebarMenuItem>` in nav-main): React makes that element the
   * collapsible root. The library collapsible is a div, and a div between `<ul>` and `<li>` breaks list semantics,
   * so the child element stays outermost and the collapsible wraps its children (classes such as
   * `group/collapsible` stay on the collapsible, so `group-data-[state=open]/collapsible:` still applies).
   */
  private collapsibleAsChild(node: t.JSXElement, reactName: string, ctx: Ctx): HNode[] {
    const nodes = this.generic(node, this.meta.functions.get("collapsible")!, reactName, ctx)
    const roots = nodes.filter((entry): entry is HElement => entry.k === "el")
    const kids = roots[0]?.children.filter(entry => entry.k !== "text" || entry.v.trim())
    const child = kids?.length === 1 && kids[0].k === "el" && !/^\.collapsible_/.test(kids[0].tag) ? kids[0] : undefined
    if (roots.length !== 1 || !child) return nodes
    const collapsible = roots[0]
    collapsible.children = child.children
    child.children = [collapsible]
    this.mapped(`${reactName} asChild`, `collapsible inside its child (${child.tag.replace(/^\./, "")})`)
    return nodes.map(entry => (entry === collapsible ? child : entry))
  }

  /**
   * ChartContainer around one Recharts AreaChart/BarChart/LineChart whose series are plain `dataKey`s →
   * `<.chart_container :let={chart}>` with `<.chart_canvas kind=...>`. Anything else becomes one TODO inside the
   * container (never loose `<defs>`/axis markup).
   */
  private chart(node: t.JSXElement, reactName: string, ctx: Ctx): HNode[] {
    const parts = this.elementChildren(node)
    const chart = parts.length === 1 ? parts[0] : undefined
    const chartName = chart ? this.rechartsName(chart, ctx) : undefined
    const recipe = chartName ? rechartsKinds[chartName] : undefined
    let body: HNode[]
    try {
      if (!chart || !chartName || !recipe) {
        const found = parts.map(part => `<${jsxName(part.openingElement.name)}>`).join(", ") || "nothing"
        throw new Unsupported(`chart_canvas draws a single Recharts ${Object.keys(rechartsKinds).join("/")}; this ChartContainer holds ${found}`)
      }
      body = this.chartCanvas(chart, chartName, recipe, ctx)
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      const target = chart ?? node
      // Literal rows the chart reads are kept as data functions; point the hand-written replacement at them.
      const sources = this.dataSources(target, ctx)
      const from = sources.length ? `; its source rows are in ${sources.map(fn => `\`${fn}()\``).join(", ")} (bottom of the module)` : ""
      body = [this.todo(ctx, target, `${error.message}${from} (source lines ${lineOf(target)}-${target.loc?.end.line ?? lineOf(target)} omitted)`, `${rules.components} (\`chart\` row)`)]
    }
    for (const part of parts) this.accounted.add(part)
    const nodes = this.generic(node, this.meta.functions.get("chart_container")!, reactName, ctx, { children: body })
    const root = nodes.find((entry): entry is HElement => entry.k === "el")
    root?.attrs.push({ name: ":let", value: "{chart}" })
    return nodes
  }

  /** Recharts component name of an element (`AreaChart`, `XAxis`, ...), undefined for anything else. */
  private rechartsName(element: t.JSXElement, ctx: Ctx): string | undefined {
    const name = jsxName(element.openingElement.name)
    const kind = this.componentKind(name, ctx)
    return kind?.kind === "unknown" && kind.source === "recharts" ? this.importedName(name, ctx) : undefined
  }

  /**
   * One Recharts AreaChart/BarChart/LineChart → `<.chart_canvas>`. Props with a chart_canvas equivalent map onto its
   * attrs (`stackId` → `stack`, `type` → `curve`, `<defs>` gradients → `fill="gradient"` + per-series
   * `gradient_opacity`, `CartesianGrid` → `grid`, XAxis tick options, formatters → `tick_format`/
   * `tooltip_label_format`, `ChartTooltip cursor`); every other prop is listed in one note. Rows React computes
   * (`data={filteredData}`) become an assign seeded with the source rows, plus one TODO for the computation only.
   */
  private chartCanvas(chart: t.JSXElement, chartName: string, recipe: { kind: string; series: string }, ctx: Ctx): HNode[] {
    const dropped: string[] = []
    const handled = [jsxName(chart.openingElement.name)]
    const literal = (element: t.JSXElement, name: string) => {
      const value = this.jsxAttrExpr(element, name)
      return value?.type === "StringLiteral" || value?.type === "NumericLiteral" || value?.type === "BooleanLiteral" ? value.value : undefined
    }
    /** Lists the props of `element` outside `mapped` as dropped. */
    const rest = (element: t.JSXElement, label: string, mapped: string[]) => {
      for (const attribute of element.openingElement.attributes) {
        const name = attribute.type === "JSXAttribute" ? String(attribute.name.name) : "{...spread}"
        if (name !== "key" && !mapped.includes(name)) dropped.push(`<${label} ${name}>`)
      }
    }
    rest(chart, chartName, ["data", "accessibilityLayer"])

    const gradients = new Map<string, t.JSXElement>()
    const series: { key: string; label?: string; stack?: string; curve?: string; gradient?: [number, number]; fillOpacity?: number }[] = []
    const attrs: HAttr[] = []
    const extra: HAttr[] = []
    let xKey: string | undefined
    let axes = false
    let tooltip = false
    let legend = false
    let xFormatter: t.Expression | undefined
    let labelFormatter: t.Expression | undefined
    const elements = this.elementChildren(chart)
    for (const defs of elements.filter(child => jsxName(child.openingElement.name) === "defs")) {
      for (const gradient of this.elementChildren(defs)) {
        const id = jsxName(gradient.openingElement.name) === "linearGradient" ? literal(gradient, "id") : undefined
        if (typeof id === "string") gradients.set(id, gradient)
        else dropped.push(`<defs> <${jsxName(gradient.openingElement.name)}>`)
      }
    }
    for (const child of elements) {
      const name = jsxName(child.openingElement.name)
      const recharts = this.rechartsName(child, ctx)
      const ui = this.componentKind(name, ctx)?.kind === "ui" ? this.importedName(name, ctx) : undefined
      if (recharts) handled.push(name)
      if (name === "defs") continue
      if (recharts === recipe.series) {
        const key = literal(child, "dataKey")
        if (typeof key !== "string") throw new Unsupported(`<${recharts}> without a literal dataKey`)
        const entry: (typeof series)[number] = { key }
        const label = literal(child, "name")
        if (typeof label === "string") entry.label = label
        const stack = literal(child, "stackId")
        if (stack !== undefined) entry.stack = String(stack)
        const type = literal(child, "type")
        const curve = typeof type === "string" ? ({ linear: "linear", natural: "natural", monotone: "monotone", monotoneX: "monotone", step: "step" } as Record<string, string>)[type] : undefined
        if (type !== undefined && (!curve || recipe.kind === "bar")) dropped.push(`<${recharts} type="${type}">`)
        else if (curve) entry.curve = curve
        const own = `var(--color-${key})`
        const fill = literal(child, "fill")
        const gradientId = typeof fill === "string" ? fill.match(/^url\(#(.+)\)$/)?.[1] : undefined
        if (gradientId && gradients.has(gradientId) && recipe.kind !== "line") entry.gradient = this.chartGradient(gradients.get(gradientId)!, key, dropped)
        else if (fill !== undefined && fill !== own) dropped.push(`<${recharts} fill=${typeof fill === "string" ? `"${fill}"` : `{${fill}}`}>`)
        const fillOpacity = literal(child, "fillOpacity")
        if (typeof fillOpacity === "number" && recipe.kind === "area") entry.fillOpacity = fillOpacity
        else if (fillOpacity !== undefined || this.jsxAttr(child, "fillOpacity")) dropped.push(`<${recharts} fillOpacity>`)
        const stroke = literal(child, "stroke")
        if (this.jsxAttr(child, "stroke") && stroke !== own) dropped.push(`<${recharts} stroke>`)
        rest(child, recharts, ["dataKey", "name", "stackId", "type", "fill", "fillOpacity", "stroke"])
        series.push(entry)
      } else if (recharts === "XAxis") {
        const key = literal(child, "dataKey")
        if (typeof key === "string") xKey = key
        axes = literal(child, "hide") !== true
        for (const [prop, attr] of [["axisLine", "axis_line"], ["tickLine", "tick_line"]]) {
          const value = literal(child, prop)
          if (value === false) extra.push({ name: attr, value: "{false}" })
          else if (this.jsxAttr(child, prop) && value !== true) dropped.push(`<XAxis ${prop}>`)
        }
        for (const [prop, attr] of [["tickMargin", "tick_margin"], ["minTickGap", "min_tick_gap"]]) {
          const value = literal(child, prop)
          if (typeof value === "number" && Number.isInteger(value)) extra.push({ name: attr, value: `{${value}}` })
          else if (this.jsxAttr(child, prop)) dropped.push(`<XAxis ${prop}>`)
        }
        xFormatter = this.jsxAttrExpr(child, "tickFormatter")
        rest(child, "XAxis", ["dataKey", "hide", "axisLine", "tickLine", "tickMargin", "minTickGap", "tickFormatter"])
      } else if (recharts === "CartesianGrid") {
        const horizontal = literal(child, "horizontal") !== false
        const vertical = literal(child, "vertical") !== false
        const grid = horizontal && vertical ? "both" : horizontal ? "horizontal" : vertical ? "vertical" : "none"
        if (grid !== "none") extra.push({ name: "grid", value: quoteAttr(grid) })
        rest(child, "CartesianGrid", ["horizontal", "vertical"])
      } else if (recharts === "YAxis") dropped.push("<YAxis>")
      else if (ui === "ChartTooltip") {
        tooltip = true
        const cursor = literal(child, "cursor")
        if (cursor === false) extra.push({ name: "cursor", value: "{false}" })
        else if (this.jsxAttr(child, "cursor") && cursor !== true) dropped.push("<ChartTooltip cursor>")
        const content = this.jsxAttrExpr(child, "content")
        if (content && isJsx(content) && content.type === "JSXElement" && this.importedName(jsxName(content.openingElement.name), ctx) === "ChartTooltipContent") {
          // The built-in tooltip is ChartTooltipContent with its default dot indicator.
          const indicator = literal(content, "indicator")
          if (indicator !== undefined && indicator !== "dot") dropped.push(`<ChartTooltipContent indicator="${indicator}">`)
          labelFormatter = this.jsxAttrExpr(content, "labelFormatter")
          rest(content, "ChartTooltipContent", ["indicator", "labelFormatter"])
        } else if (content) dropped.push("<ChartTooltip content>")
        rest(child, "ChartTooltip", ["cursor", "content"])
      } else if (ui === "ChartLegend") legend = true
      else throw new Unsupported(`<${name}> inside <${chartName}> has no chart_canvas equivalent`)
    }
    if (!series.length) throw new Unsupported(`<${chartName}> has no <${recipe.series} dataKey="..."> series`)

    const dataExpr = this.jsxAttrExpr(chart, "data")
    if (!dataExpr) throw new Unsupported(`<${chartName}> has no \`data\` prop`)
    const nodes: HNode[] = []
    let data: string
    let rows: Term | undefined
    try {
      data = this.expr(dataExpr, ctx)
      rows = this.resolveTerm(dataExpr, ctx)
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      // Rows computed in React (`chartData.filter(...)`): the canvas renders an assign seeded with the source rows; the
      // computation itself is the one thing left to port.
      const assign = dataExpr.type === "Identifier" ? elixirVar(dataExpr.name) : `${ctx.unit.fnName}_chart_data`
      const bindings = this.readBindings(dataExpr, ctx)
      const sources = bindings.flatMap(binding => (binding.b === "const" && this.consts.get(binding.key)!.term?.t === "list" ? [this.consts.get(binding.key)!] : []))
      for (const source of sources) source.keep = true
      const inputs = [...new Set(bindings.flatMap(binding => (binding.b === "state" ? [`@${binding.assign}`] : [])))]
      const seed = sources.length === 1 ? `${sources[0].fn}()` : "[]"
      rows = sources.length === 1 ? sources[0].term : undefined
      this.states.set(assign, { assign, code: seed, unit: ctx.unit, line: lineOf(dataExpr), scope: ctx.scope })
      data = this.assignRef(ctx, assign)
      const snippet = this.snippet(dataExpr, ctx)
      const when = inputs.length ? ` and wherever ${inputs.join(", ")} ${inputs.length === 1 ? "changes" : "change"}` : ""
      nodes.push(this.todo(ctx, dataExpr, `\`${snippet}\` is computed in React (${error.message}); \`@${assign}\` starts as ${sources.length === 1 ? `all of \`${seed}\`` : "[]"}. Port the computation and reassign \`@${assign}\` in mount/3${when}.`, rules.state))
    }
    const firstRow = rows?.t === "list" ? rows.items.find(item => item.t === "map") : undefined
    const xValue = firstRow?.t === "map" && xKey ? firstRow.entries.find(([name]) => name === elixirVar(xKey!))?.[1] : undefined
    const stringX = xValue?.t === "raw" && xValue.code.startsWith('"')
    for (const [node, attr, label] of [[xFormatter, "tick_format", "<XAxis tickFormatter>"], [labelFormatter, "tooltip_label_format", "<ChartTooltipContent labelFormatter>"]] as const) {
      if (!node) continue
      const format = this.chartFormat(node, ctx, stringX)
      if (format) extra.push({ name: attr, value: format })
      else dropped.push(label)
    }

    // Chart-wide attrs when every series agrees; per-series maps otherwise.
    const same = <T,>(values: T[]) => (values.length === series.length && new Set(values).size === 1 ? values[0] : undefined)
    const stacks = series.flatMap(entry => (entry.stack === undefined ? [] : [entry.stack]))
    const sharedStack = recipe.kind !== "line" ? same(stacks) : undefined
    if (stacks.length && recipe.kind === "line") dropped.push(`<${recipe.series} stackId>`)
    const curves = [...new Set(series.flatMap(entry => (entry.curve ? [entry.curve] : [])))]
    if (curves.length > 1) dropped.push(`per-series <${recipe.series} type> (one curve="${curves[0]}" for all)`)
    const opacities = series.flatMap(entry => (entry.fillOpacity === undefined ? [] : [entry.fillOpacity]))
    const sharedOpacity = same(opacities)
    const gradient = series.some(entry => entry.gradient)
    if (gradient && series.some(entry => !entry.gradient)) dropped.push(`solid <${recipe.series} fill> beside gradient series (all series use gradients)`)
    const seriesMaps = series.map(entry => {
      const fields: string[] = []
      if (entry.label) fields.push(`label: ${elixirString(entry.label)}`)
      if (entry.stack !== undefined && sharedStack === undefined && recipe.kind !== "line") fields.push(`stack: ${elixirString(entry.stack)}`)
      if (entry.fillOpacity !== undefined && sharedOpacity === undefined) fields.push(`fill_opacity: ${chartNumber(entry.fillOpacity)}`)
      if (entry.gradient) fields.push(`gradient_opacity: [${entry.gradient.map(chartNumber).join(", ")}]`)
      return fields.length ? `%{key: ${elixirString(entry.key)}, ${fields.join(", ")}}` : elixirString(entry.key)
    })

    for (const name of handled) this.handledImports.add(`${ctx.unit.parsed.file}#${name.split(".")[0]}`)
    if (dropped.length) this.note(ctx, chart, `chart_canvas kind="${recipe.kind}" approximates ${chartName}; no equivalent for: ${[...new Set(dropped)].join(", ")}.`)
    this.mapped(chartName, `chart_canvas kind="${recipe.kind}"`)
    attrs.push(
      { name: "id", value: this.idFor(ctx, undefined, "chart-canvas").attr },
      { name: "context", value: "{chart}" },
      { name: "kind", value: quoteAttr(recipe.kind) },
      { name: "data", value: `{${data}}` },
      { name: "series", value: `{[${seriesMaps.join(", ")}]}` },
    )
    if (xKey) attrs.push({ name: "x_key", value: quoteAttr(xKey) })
    if (!axes) attrs.push({ name: "axes", value: "{false}" })
    if (!tooltip) attrs.push({ name: "tooltip", value: "{false}" })
    if (legend) attrs.push({ name: "legend", value: "{true}" })
    // Recharts stacks series sharing a stackId; one shared id is chart_canvas's bare `stack`.
    if (sharedStack !== undefined) attrs.push({ name: "stack" })
    if (curves.length && curves[0] !== "linear" && recipe.kind !== "bar") attrs.push({ name: "curve", value: quoteAttr(curves[0]) })
    if (gradient) attrs.push({ name: "fill", value: '"gradient"' })
    if (sharedOpacity !== undefined && sharedOpacity !== 0.6) attrs.push({ name: "fill_opacity", value: `{${chartNumber(sharedOpacity)}}` })
    // A hidden X axis (`<XAxis hide>`) draws no ticks, so its tick options would only be noise.
    const axisAttrs = ["axis_line", "tick_line", "tick_margin", "min_tick_gap", "tick_format"]
    const order = ["grid", ...axisAttrs, "tooltip_label_format", "cursor"]
    attrs.push(...extra.filter(attr => axes || !axisAttrs.includes(attr.name)).sort((a, b) => order.indexOf(a.name) - order.indexOf(b.name)))
    nodes.push(el(".chart_canvas", attrs))
    return nodes
  }

  /** `fill="url(#id)"`'s vertical `<linearGradient>` → its first/last stop opacities (chart_canvas stops: 5%/95%). */
  private chartGradient(gradient: t.JSXElement, key: string, dropped: string[]): [number, number] {
    const value = (element: t.JSXElement, name: string) => {
      const expression = this.jsxAttrExpr(element, name)
      return expression?.type === "StringLiteral" || expression?.type === "NumericLiteral" ? String(expression.value) : undefined
    }
    const id = value(gradient, "id")
    if ((value(gradient, "x1") ?? "0") !== (value(gradient, "x2") ?? "1")) dropped.push(`<linearGradient id="${id}"> direction (chart_canvas gradients are vertical)`)
    const stops = this.elementChildren(gradient).filter(stop => jsxName(stop.openingElement.name) === "stop")
    const opacity = (stop: t.JSXElement | undefined) => {
      const number = stop ? Number(value(stop, "stopOpacity") ?? 1) : NaN
      return Number.isFinite(number) ? number : 1
    }
    if (stops.length !== 2 || value(stops[0], "offset") !== "5%" || value(stops[1], "offset") !== "95%") dropped.push(`<linearGradient id="${id}"> stop offsets (chart_canvas uses 5%/95%)`)
    if (stops.some(stop => value(stop, "stopColor") !== `var(--color-${key})`)) dropped.push(`<linearGradient id="${id}"> stopColor (gradients use the series color)`)
    return [opacity(stops[0]), opacity(stops.at(-1))]
  }

  /**
   * A Recharts tick/label formatter as a chart_canvas format: `"date_short"` for
   * `new Date(value).toLocaleDateString("en-US", {month: "short", day: "numeric"})`, otherwise a server-side
   * `fn value -> ... end` when the body converts (`value.slice(0, 3)`); undefined when it does not.
   */
  private chartFormat(node: t.Expression, ctx: Ctx, stringValues: boolean): string | undefined {
    const fn = unwrap(node)
    if ((fn.type !== "ArrowFunctionExpression" && fn.type !== "FunctionExpression") || fn.params.length !== 1 || fn.params[0].type !== "Identifier") return undefined
    const param = fn.params[0].name
    const statements = fn.body.type === "BlockStatement" ? fn.body.body : []
    const last = statements.at(-1)
    const returned = fn.body.type === "BlockStatement" ? (last?.type === "ReturnStatement" ? last.argument : undefined) : fn.body
    if (!returned) return undefined
    const dates = new Set<string>()
    const isDate = (value: t.Node | null | undefined) => {
      const expression = value && unwrap(value as t.Expression)
      if (expression?.type === "Identifier") return dates.has(expression.name)
      return expression?.type === "NewExpression" && expression.callee.type === "Identifier" && expression.callee.name === "Date"
        && expression.arguments.length === 1 && expression.arguments[0].type === "Identifier" && expression.arguments[0].name === param
    }
    let plain = true
    for (const statement of statements.slice(0, -1)) {
      const declarator = statement.type === "VariableDeclaration" && statement.declarations.length === 1 ? statement.declarations[0] : undefined
      if (declarator?.id.type === "Identifier" && isDate(declarator.init)) dates.add(declarator.id.name)
      else plain = false
    }
    const call = unwrap(returned)
    if (plain && call.type === "CallExpression" && call.callee.type === "MemberExpression" && call.callee.property.type === "Identifier"
      && call.callee.property.name === "toLocaleDateString" && isDate(call.callee.object)) {
      const [locale, options] = call.arguments
      const props = options?.type === "ObjectExpression" ? options.properties : []
      const option = (name: string) => props.find((prop): prop is t.ObjectProperty => prop.type === "ObjectProperty" && prop.key.type === "Identifier" && prop.key.name === name)?.value
      const text = (value: t.Node | undefined) => (value?.type === "StringLiteral" ? value.value : undefined)
      // No locale (`undefined`) is the browser's; en-US is what shadcn templates assume and date_short renders.
      const noLocale = !locale || (locale.type === "Identifier" && locale.name === "undefined")
      if ((noLocale || text(locale) === "en-US") && props.length === 2 && text(option("month")) === "short" && text(option("day")) === "numeric") return '"date_short"'
      return undefined
    }
    if (statements.length > 1) return undefined
    const variable = elixirVar(param)
    const inner: Ctx = { ...ctx, scope: new Map(ctx.scope) }
    inner.scope.set(param, { b: "code", code: variable, string: stringValues })
    try {
      const body = this.expr(returned, inner)
      return `{fn ${new RegExp(`\\b${variable}\\b`).test(body) ? variable : `_${variable}`} -> ${body} end}`
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      return undefined
    }
  }

  /** Bindings an expression reads, through locals (`filteredData` → `chartData`, `timeRange`). */
  private readBindings(node: t.Node, ctx: Ctx, seen = new Set<t.Node>()): Binding[] {
    if (seen.has(node)) return []
    seen.add(node)
    if (node.type === "Identifier") {
      const binding = this.lookup(node.name, ctx)
      if (!binding) return []
      return binding.b === "local" ? [binding, ...this.readBindings(binding.node, binding.ctx, seen)] : [binding]
    }
    const found: Binding[] = []
    for (const [field, value] of Object.entries(node)) {
      if (["loc", "start", "end", "leadingComments", "trailingComments", "innerComments"].includes(field)) continue
      // `item.date` reads the property name, not a binding.
      if (field === "property" && (node.type === "MemberExpression" || node.type === "OptionalMemberExpression") && !node.computed) continue
      if (field === "key" && node.type === "ObjectProperty" && !node.computed) continue
      for (const child of Array.isArray(value) ? value : [value]) {
        if (child && typeof child === "object" && typeof child.type === "string") found.push(...this.readBindings(child, ctx, seen))
      }
    }
    return found
  }

  /** Data lists an expression reads (`filteredData` = `chartData.filter(...)` → `chart_data`); kept even if unused. */
  private dataSources(node: t.Node, ctx: Ctx): string[] {
    const sources = this.readBindings(node, ctx).flatMap(binding => (binding.b === "const" && this.consts.get(binding.key)!.term?.t === "list" ? [this.consts.get(binding.key)!] : []))
    for (const source of sources) source.keep = true
    return [...new Set(sources.map(source => source.fn))]
  }

  private generic(node: t.JSXElement, fn: FnMeta, reactName: string, ctx: Ctx, extra: { attrs?: HAttr[]; skip?: Record<string, true>; children?: HNode[] } = {}): HNode[] {
    this.visited.add(node)
    const skip: Record<string, true> = { asChild: true, ...extra.skip, ...this.consumedStateProps(node, fn, ctx) }
    const yields = yieldingRoots[fn.name]
    const inner: Ctx = { ...ctx, contexts: new Map(ctx.contexts) }
    const attrs: HAttr[] = [...(extra.attrs ?? [])]
    let children: HNode[] | undefined = extra.children
    let linkClass: string | undefined

    // asChild: a link child becomes `href`/`navigate`; a CollapsibleTrigger child makes this component the toggle.
    const asChild = this.jsxAttr(node, "asChild") && fn.name !== "collapsible" ? this.elementChildren(node)[0] : undefined
    if (asChild && !extra.children) {
      this.visited.add(asChild)
      const childName = jsxName(asChild.openingElement.name)
      const childKind = this.componentKind(childName, ctx)
      if (childKind?.kind === "ui" && this.importedName(childName, ctx) === "CollapsibleTrigger") {
        attrs.push(...this.collapsibleToggle(ctx, asChild))
        if (fn.attrs.has("tag")) attrs.push({ name: "tag", value: '"button"' })
        linkClass = this.plainAttrs(asChild, ctx, undefined, { asChild: true }).find(attr => attr.name === "class")?.value
        children = this.children(asChild.children, inner)
        this.mapped(`${reactName} asChild <CollapsibleTrigger>`, `${fn.name} phx-click toggling the collapsible`)
      } else if (childName !== "a" && childKind?.kind !== "next-link") {
        throw new Unsupported(`asChild with a <${childName}> child`)
      } else {
        const href = this.jsxAttrExpr(asChild, "href")
        const hrefCode = href ? this.expr(href, ctx) : '"#"'
        const internal = /^"\/[^/]/.test(hrefCode) || (childKind?.kind === "next-link" && !/^"(#|https?:)/.test(hrefCode))
        const linkAttr = internal && fn.attrs.has("navigate") ? "navigate" : "href"
        if (!acceptsAttr(fn, linkAttr)) {
          // e.g. DropdownMenuItem asChild <a>: keep the link inside the item.
          this.note(ctx, asChild, `${fn.name}/1 has no ${linkAttr}; the asChild link was nested inside it (keyboard selection does not follow the link).`)
          children = this.child(asChild, inner)
        } else {
          if (linkAttr === "href" && fn.attrs.get("tag")?.defaultValue === '"button"') attrs.push({ name: "tag", value: '"a"' })
          attrs.push({ name: linkAttr, value: codeAttr(hrefCode) })
          const childAttrs = this.plainAttrs(asChild, ctx, undefined, { href: true })
          linkClass = childAttrs.find(attr => attr.name === "class")?.value
          attrs.push(...childAttrs.filter(attr => attr.name !== "class" && acceptsAttr(fn, attr.name)))
          children = this.children(asChild.children, inner)
          this.mapped(`${reactName} asChild <${childName}>`, `${fn.name} ${linkAttr}=`)
        }
      }
    }

    attrs.push(...this.plainAttrs(node, ctx, fn, skip))

    if (linkClass) {
      const own = attrs.find(attr => attr.name === "class")
      const parts = [own?.value, linkClass].filter((part): part is string => !!part).map(part => (part.startsWith("{") ? part.slice(1, -1) : JSON.stringify(part.slice(1, -1))))
      if (own) attrs.splice(attrs.indexOf(own), 1)
      attrs.push({ name: "class", value: parts.length === 1 ? (parts[0].startsWith('"') ? parts[0] : `{${parts[0]}}`) : `{[${parts.join(", ")}]}` })
    }

    // Required context attrs (`context`, `sidebar`, ...) come from the nearest provider.
    for (const attr of fn.attrs.values()) {
      if (attr.type !== ":map" || attrs.some(existing => existing.name === attr.name)) continue
      const key = contextKey(fn.name, fn.family, attr.name)
      const available = ctx.contexts.get(key) ?? (attr.required && !ctx.unit.entry ? this.contextRef(ctx, key, node) : undefined)
      if (available) attrs.unshift({ name: attr.name, value: `{${available}}` })
      else if (attr.required) throw new Unsupported(`needs \`${attr.name}\` from an enclosing ${key} provider that is not part of this template`)
    }

    // Hooked roots need a stable id even when the attr is optional (radio_group, ...).
    const hooked = !!yields || fn.attrs.has("on_change") || fn.attrs.has("on_value_change")
    if ((fn.attrs.get("id")?.required || (hooked && fn.attrs.has("id"))) && !attrs.some(attr => attr.name === "id")) {
      attrs.unshift({ name: "id", value: this.idFor(ctx, undefined, fn.name.replace(/_/g, "-")).attr })
    }
    // Other required attrs/slots the React API leaves optional: derive `value` from the text, otherwise give up.
    for (const attr of fn.attrs.values()) {
      if (!attr.required || attr.type === ":map" || attrs.some(existing => existing.name === attr.name)) continue
      const text = this.staticText(node, ctx)
      if (attr.name === "value" && text) attrs.push({ name: "value", value: quoteAttr(kebab(text) || text) })
      else throw new Skip(`${fn.name}/1 requires \`${attr.name}\`, which the template does not provide`)
    }
    const slot = [...fn.slots.values()].find(candidate => candidate.required && candidate.name !== "inner_block")
    if (slot) throw new Skip(`${fn.name}/1 is composed with a <:${slot.name}> slot; rebuild this part from the ${fn.family} docs`)

    // The installer's CoreComponents button defaults to `outline`; be explicit so both setups match React.
    if (fn.name === "button" && !attrs.some(attr => attr.name === "variant")) attrs.push({ name: "variant", value: '"default"' })

    this.stateAttrs(node, fn, attrs, ctx, inner)

    if (yields) {
      // Never shadow a loop variable (`:for={item <- ...}` with accordion_item's `:let={item}`).
      const taken = [...ctx.scope.values()].some(binding => binding.b === "code" && new RegExp(`^${yields.variable}\\b`).test(binding.code))
      const variable = taken ? `${yields.key}_ctx` : yields.variable
      inner.contexts.set(yields.key, variable)
      attrs.push({ name: ":let", value: `{${variable}}` })
    }
    if (ctx.form && fieldControls[fn.name]) this.bindField(node, fn, attrs, ctx)

    const tag = qualifiedFunctions[fn.name] ? `${qualifiedFunctions[fn.name]}.${fn.name}` : `.${fn.name}`
    if (qualifiedFunctions[fn.name]) this.qualified.add(qualifiedFunctions[fn.name])
    this.mapped(reactName, fn.name)
    return [el(tag, attrs, children ?? this.childrenOrRestSlot(node, attrs, inner))]
  }

  /** React state props that stateAttrs converts (so plainAttrs must not report them). */
  private consumedStateProps(node: t.JSXElement, fn: FnMeta, ctx: Ctx): Record<string, true> {
    if (fn.name === "collapsible" || fn.name === "sidebar_provider") return { open: true, defaultOpen: true, onOpenChange: true }
    const consumed: Record<string, true> = {}
    for (const name of ["onValueChange", "onCheckedChange", "onPressedChange"]) {
      if (this.payloadSetter(this.jsxAttrExpr(node, name), ctx) && (fn.attrs.has("on_value_change") || fn.attrs.has("on_change"))) consumed[name] = true
    }
    return consumed
  }

  /** Uncontrolled React defaults map to `default_*`; React-controlled state to assigns + events. */
  private stateAttrs(node: t.JSXElement, fn: FnMeta, attrs: HAttr[], ctx: Ctx, inner: Ctx): void {
    const setAttr = (name: string, value: string) => {
      const existing = attrs.find(attr => attr.name === name)
      if (existing) existing.value = value
      else attrs.push({ name, value })
    }
    const onValue = ["onValueChange", "onCheckedChange", "onPressedChange"].map(name => this.jsxAttrExpr(node, name)).find(Boolean)
    const setter = this.payloadSetter(onValue, ctx)
    const changeAttr = fn.attrs.has("on_value_change") ? "on_value_change" : fn.attrs.has("on_change") ? "on_change" : undefined
    if (setter && changeAttr) {
      const event = `change_${setter}`
      setAttr(changeAttr, elixirString(event))
      // Radix single toggle groups send "" when the pressed item is clicked again. A state that starts non-empty
      // (`useState("90d")`, the time-range pattern) keeps its value instead, so the controls bound to it never go blank.
      const type = this.jsxAttrExpr(node, "type")
      const init = this.states.get(setter)?.init
      const keepValue = fn.name === "toggle_group" && type?.type === "StringLiteral" && type.value === "single" && init?.type === "StringLiteral" && init.value !== ""
      if (keepValue) this.note(ctx, node, `toggle_group: clicking the pressed item sends \`""\`; \`${event}\` ignores it so \`@${setter}\` keeps a value (React would set "" here). Remove the \`%{"value" => ""}\` clause if an empty selection is valid.`)
      this.addClause(event, "value", { assign: setter, line: lineOf(node), keepValue })
    }
    if (fn.name !== "collapsible" && fn.name !== "sidebar_provider") return

    const idAttr = attrs.find(attr => attr.name === "id")!.value!
    const id = idAttr.startsWith("{") ? idAttr.slice(1, -1) : elixirString(idAttr.slice(1, -1))
    const openSetter = this.payloadSetter(this.jsxAttrExpr(node, "onOpenChange"), ctx)
    const open = this.jsxAttrExpr(node, "open")
    const defaultOpen = this.jsxAttrExpr(node, "defaultOpen")
    if (fn.name === "collapsible" && open && openSetter) {
      const event = elixirString(`change_${openSetter}`)
      setAttr("open", `{${this.expr(open, ctx)}}`)
      setAttr("on_open_change", event)
      inner.contexts.set("collapsible_event", event)
      this.addClause(`change_${openSetter}`, "open", { assign: openSetter, line: lineOf(node) })
      return
    }
    if (open) this.note(ctx, node, `${fn.name}: controlled React \`open\` replaced by generated @ui state; wire it to your own assign if needed.`)
    const fallback = defaultOpen ? this.condition(defaultOpen, ctx) : fn.name === "sidebar_provider" ? "true" : "false"
    setAttr("open", `{${this.uiState(ctx, id, fallback)}}`)
    if (fn.name === "collapsible") {
      inner.contexts.set("collapsible_event", '"control_open"')
      this.addClause("control_open", "open", { uiKey: "id", line: lineOf(node) })
    } else {
      setAttr("mobile_open", `{${this.uiState(ctx, `${id} <> "-mobile"`, "false")}}`)
      this.addClause("shadcn:sidebar-change", "open", { uiKey: "id", line: lineOf(node) })
    }
  }

  /** `CollapsibleTrigger asChild`: the child element toggles the collapsible through its event. */
  private collapsibleTrigger(node: t.JSXElement, reactName: string, ctx: Ctx): HNode[] {
    const child = this.elementChildren(node)[0]
    if (!child) throw new Unsupported("asChild trigger without an element child")
    const toggle = this.collapsibleToggle(ctx, node)
    const nodes = this.child(child, ctx)
    const target = nodes.find((n): n is HElement => n.k === "el")
    if (!target) throw new Unsupported("asChild trigger child did not convert to an element")
    target.attrs.push(...toggle)
    this.mapped(`${reactName} asChild`, "phx-click toggling the collapsible")
    return nodes
  }

  /** Attributes that make any element toggle the enclosing collapsible like `collapsible_trigger`. */
  private collapsibleToggle(ctx: Ctx, node: t.Node): HAttr[] {
    const variable = ctx.contexts.get("collapsible") ?? this.contextRef(ctx, "collapsible", node)
    const event = ctx.contexts.get("collapsible_event") ?? '"control_open"'
    this.usesJS = true
    return [
      { name: "phx-click", value: `{JS.push(${event}, value: %{id: ${variable}.id, open: !${variable}.open})}` },
      { name: "aria-expanded", value: `{to_string(${variable}.open)}` },
      { name: "data-state", value: `{if(${variable}.open, do: "open", else: "closed")}` },
    ]
  }

  /** `DialogClose asChild` (and alert action/cancel): the child closes the modal. */
  private modalClose(node: t.JSXElement, family: string, reactName: string, ctx: Ctx): HNode[] {
    const variable = ctx.contexts.get(family) ?? this.contextRef(ctx, family, node)
    const child = this.elementChildren(node)[0]
    if (!child) throw new Unsupported("asChild close without an element child")
    const nodes = this.child(child, ctx)
    const target = nodes.find((n): n is HElement => n.k === "el")
    if (!target) throw new Unsupported("asChild close child did not convert to an element")
    target.attrs = target.attrs.filter(attr => attr.name !== "phx-click")
    target.attrs.push({ name: "phx-click", value: `{${variable}.on_close}` })
    this.mapped(`${reactName} asChild`, `phx-click={${variable}.on_close}`)
    return nodes
  }

  private flattenSubmenu(node: t.JSXElement, fnName: string, ctx: Ctx): HNode[] {
    const family = fnName.replace(/_sub$/, "")
    const pascal = toPascalCase(family)
    const trigger = this.findPart(node, ctx, `${pascal}SubTrigger`)
    const content = this.findPart(node, ctx, `${pascal}SubContent`)
    for (const part of [trigger, content]) if (part) this.visited.add(part)
    const label = trigger ? this.children(trigger.children, ctx) : []
    const items = content ? this.children(content.children, ctx) : []
    this.todo(ctx, node, `${family} submenus are not supported by shadcn_liveview; the submenu items were inlined under a label`, rules.popup)
    return [
      el(`.${family}_separator`),
      el(`.${family}_label`, [], label),
      el(`.${family}_group`, [], items),
    ]
  }

  /** dropdown_menu / popover / tooltip / hover_card / context_menu. */
  private popup(node: t.JSXElement, fnName: string, ctx: Ctx): HNode[] {
    const fn = this.meta.functions.get(fnName)
    if (!fn) throw new Unsupported(`${fnName}/1 missing`)
    const recipe = popupFamilies[fnName]
    const pascal = toPascalCase(fnName)
    const trigger = this.findPart(node, ctx, `${pascal}Trigger`)
    const content = this.findPart(node, ctx, `${pascal}Content`)
    if (!trigger || !content) throw new Unsupported(`expected ${pascal}Trigger and ${pascal}Content`)
    const id = this.idFor(ctx, this.jsxAttrExpr(node, "id"), fnName.replace(/_/g, "-"))
    const attrs: HAttr[] = [{ name: "id", value: id.attr }]
    const openSetter = this.payloadSetter(this.jsxAttrExpr(node, "onOpenChange"), ctx)
    const open = this.jsxAttrExpr(node, "open")
    if (open && openSetter) {
      attrs.push({ name: "open", value: `{${this.expr(open, ctx)}}` }, { name: "on_change", value: elixirString(`change_${openSetter}`) })
      this.addClause(`change_${openSetter}`, "action", { assign: openSetter, line: lineOf(node) })
    } else {
      const defaultOpen = this.jsxAttrExpr(node, "defaultOpen")
      attrs.push({ name: "open", value: `{${this.uiState(ctx, id.code, defaultOpen ? this.condition(defaultOpen, ctx) : "false")}}` })
      this.addClause("shadcn:popup-change", "action", { uiKey: "id", line: lineOf(node) })
    }
    // Positioning props live on the root in shadcn_liveview.
    const contentFn = this.meta.functions.get(recipe.contentFn)!
    const moved: Record<string, true> = {}
    for (const prop of ["side", "align", "sideOffset", "dir"]) {
      const expression = this.jsxAttrExpr(content, prop)
      const attr = elixirVar(prop)
      if (!expression || contentFn.attrs.has(attr) || !fn.attrs.has(attr)) continue
      moved[prop] = true
      const value = unwrap(expression)
      const allowed = fn.attrs.get(attr)?.values
      if (value.type === "StringLiteral" && allowed && !allowed.includes(value.value)) {
        this.todo(ctx, value, `${fnName} ${attr}="${value.value}" is not one of ${allowed.join("/")}`, rules.popup)
        continue
      }
      attrs.push({ name: attr, value: value.type === "StringLiteral" ? quoteAttr(value.value) : codeAttr(this.expr(value, ctx)) })
    }
    for (const prop of ["modal", "delayDuration"]) if (this.jsxAttr(node, prop)) this.note(ctx, node, `${fnName}: React prop \`${prop}\` dropped.`)

    const slotCtx: Ctx = { ...ctx, contexts: new Map(ctx.contexts) }
    slotCtx.contexts.set(fnName, "popup")
    const triggerNodes = this.popupTrigger(trigger, fnName, recipe.trigger, slotCtx)
    const contentNodes = this.generic(content, contentFn, this.importedName(jsxName(content.openingElement.name), ctx), slotCtx, { skip: moved })
    this.mapped(this.importedName(jsxName(node.openingElement.name), ctx), fnName)
    const popupNode = el(`.${fnName}`, attrs, [
      el(":trigger", [{ name: ":let", value: "{popup}" }], triggerNodes),
      el(":content", [{ name: ":let", value: "{popup}" }], contentNodes),
    ])
    return this.placeParts(node, ctx, [popupNode], trigger, content)
  }

  /**
   * Renders the converted family root where its trigger was (or its content, without a trigger),
   * keeping wrapper markup that React placed between the root and its parts.
   */
  private placeParts(root: t.JSXElement, ctx: Ctx, converted: HNode[], anchor: t.JSXElement | undefined, ...parts: (t.JSXElement | undefined)[]): HNode[] {
    if (this.onlyParts(root, [anchor, ...parts])) return converted
    const replace = new Map(ctx.replace)
    for (const part of parts) if (part) replace.set(part, [])
    replace.set(anchor ?? parts.find(Boolean)!, converted)
    this.note(ctx, root, "wrapper markup between a family root and its trigger/content was kept around the converted component; check the DOM order.")
    return this.children(root.children, { ...ctx, replace })
  }

  private popupTrigger(trigger: t.JSXElement, fnName: string, style: "spread" | "component", ctx: Ctx): HNode[] {
    this.visited.add(trigger)
    const reactName = this.importedName(jsxName(trigger.openingElement.name), ctx)
    if (style === "component") {
      const fn = this.meta.functions.get(`${fnName}_trigger`)!
      if (this.jsxAttr(trigger, "asChild")) {
        const child = this.elementChildren(trigger)[0]
        return this.generic(trigger, fn, reactName, ctx, { skip: { asChild: true }, children: child ? this.child(child, ctx) : [] })
      }
      return this.generic(trigger, fn, reactName, ctx)
    }
    this.mapped(reactName, `<:trigger> {popup.trigger}`)
    if (this.jsxAttr(trigger, "asChild")) {
      const child = this.elementChildren(trigger)[0]
      if (!child) throw new Unsupported("asChild trigger without an element child")
      const nodes = this.child(child, ctx)
      const target = nodes.find((n): n is HElement => n.k === "el")
      if (!target) throw new Unsupported("asChild trigger child did not convert to an element")
      target.attrs = target.attrs.filter(attr => attr.name !== "id")
      target.attrs.push({ name: "{popup.trigger}" })
      return nodes
    }
    return [el("button", [...this.plainAttrs(trigger, ctx, undefined), { name: "{popup.trigger}" }], this.children(trigger.children, ctx))]
  }

  /** dialog / alert_dialog / sheet / drawer. */
  private modal(node: t.JSXElement, fnName: string, ctx: Ctx): HNode[] {
    const fn = this.meta.functions.get(fnName)
    if (!fn) throw new Unsupported(`${fnName}/1 missing`)
    const pascal = toPascalCase(fnName)
    const trigger = this.findPart(node, ctx, `${pascal}Trigger`)
    const content = this.findPart(node, ctx, `${pascal}Content`)
    if (!content) throw new Unsupported(`expected a ${pascal}Content child`)
    const id = this.idFor(ctx, this.jsxAttrExpr(node, "id"), fnName.replace(/_/g, "-"))
    const attrs: HAttr[] = [{ name: "id", value: id.attr }]
    const openSetter = this.payloadSetter(this.jsxAttrExpr(node, "onOpenChange"), ctx)
    const open = this.jsxAttrExpr(node, "open")
    this.usesJS ||= !!openSetter
    if (open && openSetter) {
      const event = `set_${openSetter}`
      attrs.push(
        { name: "open", value: `{${this.expr(open, ctx)}}` },
        { name: "on_open", value: `{JS.push(${elixirString(event)}, value: %{${openSetter}: true})}` },
        { name: "on_close", value: `{JS.push(${elixirString(event)}, value: %{${openSetter}: false})}` },
      )
      this.addClause(event, "push", { assigns: [openSetter], line: lineOf(node) })
    } else {
      const defaultOpen = this.jsxAttrExpr(node, "defaultOpen")
      attrs.push({ name: "open", value: `{${this.uiState(ctx, id.code, defaultOpen ? this.condition(defaultOpen, ctx) : "false")}}` })
      this.addClause("shadcn:modal-open", "push", { uiKey: "open", line: lineOf(node) })
      this.addClause("shadcn:modal-close", "push", { uiKey: "close", line: lineOf(node) })
    }
    for (const prop of ["direction", "modal", "dismissible"]) {
      const expression = this.jsxAttrExpr(node, prop)
      if (expression && fn.attrs.has(prop)) attrs.push({ name: prop, value: expression.type === "StringLiteral" ? quoteAttr(expression.value) : `{${this.expr(expression, ctx)}}` })
    }
    const slotCtx: Ctx = { ...ctx, contexts: new Map(ctx.contexts) }
    slotCtx.contexts.set(fnName, "modal")
    const slots: HNode[] = []
    if (trigger) {
      this.visited.add(trigger)
      const reactName = this.importedName(jsxName(trigger.openingElement.name), ctx)
      if (this.jsxAttr(trigger, "asChild")) {
        const child = this.elementChildren(trigger)[0]
        const nodes = child ? this.child(child, slotCtx) : []
        const target = nodes.find((n): n is HElement => n.k === "el")
        if (target) {
          target.attrs = target.attrs.filter(attr => attr.name !== "id" && attr.name !== "phx-click")
          target.attrs.push({ name: "id", value: "{modal.trigger_id}" }, { name: "phx-click", value: "{modal.on_open}" })
        }
        this.mapped(`${reactName} asChild`, "<:trigger> phx-click={modal.on_open}")
        slots.push(el(":trigger", [{ name: ":let", value: "{modal}" }], nodes))
      } else {
        slots.push(el(":trigger", [{ name: ":let", value: "{modal}" }], this.generic(trigger, this.meta.functions.get(`${fnName}_trigger`)!, reactName, slotCtx)))
      }
    }
    const contentFn = this.meta.functions.get(`${fnName}_content`)!
    const hasTitle = !!this.findDeep(content, ctx, "Title")
    const hasDescription = !!this.findDeep(content, ctx, "Description")
    const contentAttrs: HAttr[] = []
    if (hasTitle) contentAttrs.push({ name: "aria-labelledby", value: "{modal.title_id}" })
    if (hasDescription) contentAttrs.push({ name: "aria-describedby", value: "{modal.description_id}" })
    const contentNodes = this.generic(content, contentFn, this.importedName(jsxName(content.openingElement.name), ctx), slotCtx, { attrs: contentAttrs })
    slots.push(el(":content", [{ name: ":let", value: "{modal}" }], contentNodes))
    this.mapped(this.importedName(jsxName(node.openingElement.name), ctx), fnName)
    return this.placeParts(node, ctx, [el(`.${fnName}`, attrs, slots)], trigger, content)
  }

  private findDeep(node: t.JSXElement, ctx: Ctx, suffix: string): t.JSXElement | undefined {
    for (const child of this.elementChildren(node)) {
      if (this.importedName(jsxName(child.openingElement.name), ctx).endsWith(suffix)) return child
      const found = this.findDeep(child, ctx, suffix)
      if (found) return found
    }
    return undefined
  }

  /** shadcn Select → `<.select>` with `<:trigger>` and `<:option>`/`<:group>` slots. */
  private select(node: t.JSXElement, ctx: Ctx): HNode[] {
    const trigger = this.findPart(node, ctx, "SelectTrigger")
    const content = this.findPart(node, ctx, "SelectContent")
    if (!trigger || !content) throw new Unsupported("expected SelectTrigger and SelectContent")
    // `<SelectTrigger id>` is what `<Label htmlFor>` targets: it stays the trigger's id (`trigger_id`), not the root's.
    const triggerIdExpr = this.jsxAttrExpr(trigger, "id")
    const id = this.idFor(ctx, this.jsxAttrExpr(node, "id"), "select")
    const attrs: HAttr[] = [{ name: "id", value: id.attr }]
    if (triggerIdExpr) attrs.push({ name: "trigger_id", value: this.idFor(ctx, triggerIdExpr, "select-trigger").attr })
    const valueSetter = this.payloadSetter(this.jsxAttrExpr(node, "onValueChange"), ctx)
    const value = this.jsxAttrExpr(node, "value")
    const defaultValue = this.jsxAttrExpr(node, "defaultValue")
    attrs.push({ name: "open", value: `{${this.uiState(ctx, id.code, "false")}}` })
    if (value && valueSetter) {
      attrs.push({ name: "value", value: `{${this.expr(value, ctx)}}` }, { name: "on_change", value: elixirString(`change_${valueSetter}`) })
      this.addClause(`change_${valueSetter}`, "select", { assign: valueSetter, line: lineOf(node) })
    } else {
      // A Select controlled by something other than a useState pair (e.g. TanStack table state) becomes @ui state.
      const handler = this.jsxAttr(node, "onValueChange")
      if (value || handler) this.todo(ctx, handler ?? this.jsxAttr(node, "value"), `controlled Select (\`${this.snippet(handler ?? this.jsxAttr(node, "value")!, ctx)}\`) is not a useState pair; it became uncontrolled @ui state, so bind \`value\`/\`on_change\` to your own assign and handle_event/3`, rules.popup)
      attrs.push({ name: "value", value: `{${this.uiState(ctx, `${id.code} <> "-value"`, defaultValue ? this.expr(defaultValue, ctx) : "nil")}}` })
      this.addClause("shadcn:popup-change", "select", { uiKey: "id", line: lineOf(node) })
    }
    for (const prop of ["name", "required", "disabled"]) {
      const expression = this.jsxAttrExpr(node, prop)
      if (expression) attrs.push({ name: prop, value: expression.type === "StringLiteral" ? quoteAttr(expression.value) : expression.type === "BooleanLiteral" && expression.value ? undefined : `{${this.expr(expression, ctx)}}` })
    }
    const positionAttr = this.jsxAttrExpr(content, "position")
    if (positionAttr?.type === "StringLiteral") attrs.push({ name: "position", value: quoteAttr(positionAttr.value) })
    // SelectContent placement maps to root attrs; anything else on it has no equivalent and is listed in a note.
    const unmapped: string[] = []
    for (const attribute of content.openingElement.attributes) {
      if (attribute.type !== "JSXAttribute" || attribute.name.type !== "JSXIdentifier") {
        unmapped.push("{...spread}")
        continue
      }
      const prop = attribute.name.name
      const expression = this.jsxAttrExpr(content, prop)
      const literal = expression?.type === "StringLiteral" ? expression.value : undefined
      if (prop === "position") continue
      if ((prop === "side" || prop === "align") && literal && this.meta.functions.get("select")!.attrs.get(prop)?.values?.includes(literal)) attrs.push({ name: prop, value: quoteAttr(literal) })
      else if (prop === "sideOffset" && expression?.type === "NumericLiteral") attrs.push({ name: "side_offset", value: `{${expression.value}}` })
      else unmapped.push(this.snippet(attribute, ctx))
    }
    if (unmapped.length) this.note(ctx, content, `select has no SelectContent equivalent for ${unmapped.map(prop => `\`${prop}\``).join(", ")}; dropped (style the listbox via \`[data-slot=select-content]\` in CSS if needed).`)
    const placeholder = this.findDeep(trigger, ctx, "SelectValue")
    const placeholderExpr = placeholder ? this.jsxAttrExpr(placeholder, "placeholder") : undefined
    if (placeholderExpr?.type === "StringLiteral") attrs.push({ name: "placeholder", value: quoteAttr(placeholderExpr.value) })

    const slotCtx: Ctx = { ...ctx, contexts: new Map(ctx.contexts) }
    slotCtx.contexts.set("select", "popup")
    const triggerNodes = this.generic(trigger, this.meta.functions.get("select_trigger")!, "SelectTrigger", slotCtx, { skip: { id: true } })
    const slots: HNode[] = [el(":trigger", [{ name: ":let", value: "{popup}" }], triggerNodes)]
    let groupCount = 0
    const optionsFrom = (children: t.JSXElement["children"], groupId: string | undefined, octx: Ctx): HNode[] => {
      const result: HNode[] = []
      for (const childNode of children) {
        if (childNode.type === "JSXText") continue
        if (childNode.type === "JSXExpressionContainer") {
          const expression = childNode.expression
          if (expression.type === "JSXEmptyExpression") continue
          if (expression.type === "CallExpression" && expression.callee.type === "MemberExpression" && expression.callee.property.type === "Identifier" && expression.callee.property.name === "map") {
            const callback = expression.arguments[0]
            if ((callback?.type === "ArrowFunctionExpression") && isJsx(callback.body)) {
              const inner: Ctx = { ...octx, scope: new Map(octx.scope), loopIndexes: [...octx.loopIndexes] }
              const item = callback.params[0] ? this.loopParam(callback.params[0], inner) : "_item"
              const indexParam = callback.params[1]
              const index = indexParam?.type === "Identifier" ? elixirVar(indexParam.name) : undefined
              if (indexParam?.type === "Identifier") inner.scope.set(indexParam.name, { b: "code", code: index! })
              const list = this.expr(expression.callee.object, octx)
              const options = optionsFrom([callback.body], groupId, inner)
              const gen = index ? `{${item}, ${index}} <- Enum.with_index(${list})` : `${item} <- ${list}`
              for (const option of options) if (option.k === "el") option.attrs.unshift({ name: ":for", value: `{${gen}}` })
              result.push(...options)
              continue
            }
          }
          result.push(this.todo(octx, expression, "select options from this expression; list them as <:option> slots", rules.popup))
          continue
        }
        if (childNode.type !== "JSXElement") continue
        this.visited.add(childNode)
        const name = this.importedName(jsxName(childNode.openingElement.name), octx)
        if (name === "SelectGroup") {
          const label = this.elementChildren(childNode).find(child => this.importedName(jsxName(child.openingElement.name), octx) === "SelectLabel")
          if (label) {
            groupCount++
            const gid = `${id.code.replace(/^"|"$/g, "")}-group-${groupCount}`
            const text = this.children(label.children, octx).map(n => (n.k === "text" ? n.v : "")).join("")
            slots.push(el(":group", [{ name: "id", value: quoteAttr(gid) }, { name: "label", value: quoteAttr(text) }]))
            result.push(...optionsFrom(childNode.children, gid, octx))
          } else {
            result.push(...optionsFrom(childNode.children, groupId, octx))
          }
        } else if (name === "SelectItem") {
          const valueExpr = this.jsxAttrExpr(childNode, "value")
          if (!valueExpr) {
            result.push(this.todo(octx, childNode, "SelectItem without value", rules.popup))
            continue
          }
          const valueCode = this.expr(valueExpr, octx)
          const labelNodes = this.children(childNode.children, octx)
          const labelText = labelNodes.every(n => n.k === "text") ? elixirString(labelNodes.map(n => (n.k === "text" ? n.v : "")).join("")) : valueCode
          const optionId = valueExpr.type === "StringLiteral" && !octx.loopIndexes.length ? quoteAttr(`${id.code.replace(/^"|"$/g, "")}-${kebab(valueExpr.value) || "option"}`) : `{${id.code.replace(/"$/, "")}-#{${valueCode}}"}`
          const optionAttrs: HAttr[] = [{ name: "id", value: optionId }, { name: "value", value: codeAttr(valueCode) }, { name: "label", value: codeAttr(labelText) }]
          if (groupId) optionAttrs.push({ name: "group", value: quoteAttr(groupId) })
          if (this.jsxAttr(childNode, "disabled")) optionAttrs.push({ name: "disabled" })
          const itemClass = this.jsxAttrExpr(childNode, "className")
          if (itemClass) optionAttrs.push({ name: "class", value: codeAttr(this.expr(itemClass, octx)) })
          const extra = childNode.openingElement.attributes.filter(attribute => attribute.type !== "JSXAttribute" || !["value", "disabled", "className", "key"].includes(String(attribute.name.name)))
          if (extra.length) this.note(octx, childNode, `select <:option> has no equivalent for ${extra.map(attribute => `\`${this.snippet(attribute, octx)}\``).join(", ")} on SelectItem; dropped.`)
          result.push(el(":option", optionAttrs, labelNodes))
          this.mapped("SelectItem", "<:option>")
        } else if (name === "SelectSeparator" || name === "SelectLabel" || name === "SelectScrollUpButton" || name === "SelectScrollDownButton") {
          continue
        } else {
          result.push(this.todo(octx, childNode, `<${name}> inside SelectContent; shadcn_liveview select options are plain <:option> slots`, rules.popup))
        }
      }
      return result
    }
    this.visited.add(content)
    slots.push(...optionsFrom(content.children, undefined, ctx))
    this.mapped("Select", "select")
    return [el(".select", attrs, slots)]
  }

  // ---------------------------------------------------------------- forms

  private hasFieldControls(node: t.JSXElement, ctx: Ctx): boolean {
    let found = false
    const visit = (current: t.JSXElement) => {
      for (const child of this.elementChildren(current)) {
        const name = jsxName(child.openingElement.name)
        const kind = this.componentKind(name, ctx)
        if (kind?.kind === "ui" && fieldControls[toSnakeCase(this.importedName(name, ctx))]) found = true
        if (name === "input" || name === "textarea" || name === "select") found = true
        visit(child)
      }
    }
    visit(node)
    return found
  }

  private form(node: t.JSXElement, ctx: Ctx): HNode[] {
    const stem = elixirVar(ctx.unit.decl.name.replace(/(Form|Page|Example)$/, "")) || "form"
    const base = this.forms.has(`${stem}_form`) ? `${stem}_${this.forms.size + 1}` : stem
    const assign = `${base}_form`
    this.forms.set(assign, { as: base, line: lineOf(node), file: ctx.unit.decl.file })
    const formRef = this.assignRef(ctx, assign)
    const attrs: HAttr[] = [
      { name: "for", value: `{${formRef}}` },
      { name: "id", value: codeAttr(`"${base.replace(/_/g, "-")}-form${this.keySuffix(ctx)}"`) },
      { name: "phx-change", value: quoteAttr(`validate_${base}`) },
      { name: "phx-submit", value: quoteAttr(`submit_${base}`) },
    ]
    const own = this.plainAttrs(node, ctx, undefined, { onSubmit: true, action: true, method: true })
    // The generated submit handler only re-assigns the params: a TODO in the code and in the report.
    const onSubmit = this.jsxAttr(node, "onSubmit")
    const reason = `\`submit_${base}\` is a generated placeholder that only re-assigns the params${onSubmit ? ` (React onSubmit: \`${this.snippet(onSubmit, ctx)}\`)` : ""}; validate with a changeset and persist/authenticate in it`
    this.todos.push({ file: ctx.unit.decl.file, line: lineOf(node), reason, rule: rules.forms })
    this.placeholders.push({ event: `submit_${base}`, file: ctx.unit.decl.file, line: lineOf(node) })
    if (onSubmit) this.visited.add(onSubmit)
    attrs.push(...own.filter(attr => !["id", "for"].includes(attr.name)))
    this.addClause(`validate_${base}`, "push", { assign, body: `form:${base}`, line: lineOf(node) })
    this.addClause(`submit_${base}`, "push", { assign, body: `submit:${base}`, line: lineOf(node) })
    this.mapped("<form>", ".form for={to_form(...)}")
    return [el(".form", attrs, this.children(node.children, { ...ctx, form: formRef }))]
  }

  private bindField(node: t.JSXElement, fn: FnMeta, attrs: HAttr[], ctx: Ctx): void {
    const name = this.jsxAttrExpr(node, "name") ?? this.jsxAttrExpr(node, "id")
    if (name?.type !== "StringLiteral") {
      this.note(ctx, node, `${fn.name} inside a form has no literal id/name; not bound to the form.`)
      return
    }
    attrs.push({ name: "field", value: `{${ctx.form}[:${elixirVar(name.value)}]}` })
    // `field` supplies name and value; keep the template's explicit id so labels still match.
    for (const drop of ["name", "value"]) {
      const index = attrs.findIndex(attr => attr.name === drop)
      if (index >= 0) attrs.splice(index, 1)
    }
  }

  // ---------------------------------------------------------------- module assembly

  private assemble(entry: Unit): ConvertResult {
    const component = this.opts.mode === "component"
    const web = this.opts.web ?? this.opts.module.match(/^(.*?Web)\./)?.[1]
    const lines: string[] = []
    const moduleDoc = [
      `  @moduledoc """`,
      `  Converted from the shadcn/ui template \`${this.set.label}\` by shadcn-to-liveview.`,
      "",
      "  Search for TODO(shadcn-to-liveview) and follow the conversion report before shipping.",
      `  """`,
    ]
    lines.push(`defmodule ${this.opts.module} do`, ...moduleDoc)
    if (web) lines.push(`  use ${web}, ${component ? ":html" : ":live_view"}`)
    else lines.push(component ? "  use Phoenix.Component" : "  use Phoenix.LiveView", "  use ShadcnLiveview", "", "  alias Phoenix.LiveView.JS")
    if (this.qualified.size) lines.push("", `  alias ShadcnLiveview.Components.{${[...this.qualified].sort().join(", ")}}`)
    if (this.tables.length) lines.push(...(this.qualified.size ? [] : [""]), "  alias ShadcnLiveview.DataTable")

    const pages = [...this.units.values()].filter(unit => this.referenced(unit))
    if (this.viewport) this.addClause("viewport", "push", { body: "viewport", line: 0 })
    const assigns = this.mountAssigns()
    if (this.viewport && !component) entry.heex = `${this.viewportHook()}\n${entry.heex}`
    if (this.viewport && component) this.notes.push({ file: entry.decl.file, line: 0, message: "Function-component mode: the caller passes `is_mobile` (see the viewport recipe under Required manual steps) and handles the `viewport` event." })

    if (component) {
      lines.push("")
      lines.push(...this.attrLines(entry, assigns))
      lines.push(`  def ${entry.fnName}(assigns) do`, '    ~H"""', entry.heex, '    """', "  end")
    } else {
      lines.push("", "  @impl true", "  def mount(_params, _session, socket) do")
      if (assigns.length && this.tables.length) {
        // Every table's first page is computed from its rows once the other assigns exist.
        lines.push("    {:ok,", "     socket", "     |> assign(")
        assigns.forEach(([name, code], index) => lines.push(`       ${name}: ${code}${index === assigns.length - 1 ? "" : ","}`))
        lines.push("     )", ...this.tables.map((spec, index) => `     |> load_${spec.assign}()${index === this.tables.length - 1 ? "}" : ""}`))
      } else if (assigns.length) {
        lines.push("    {:ok,", "     assign(socket,")
        assigns.forEach(([name, code], index) => lines.push(`       ${name}: ${code}${index === assigns.length - 1 ? ")}" : ","}`))
      } else {
        lines.push("    {:ok, socket}")
      }
      lines.push("  end", "", "  @impl true", "  def render(assigns) do", '    ~H"""', entry.heex, '    """', "  end")
      const handlers = this.handlerLines()
      if (handlers.length) lines.push("", ...handlers)
      if (this.uiDefaults) lines.push("", "  defp put_ui(socket, id, value), do: update(socket, :ui, &Map.put(&1, id, value))")
      for (const spec of this.tables) lines.push("", ...this.tableLoader(spec))
    }

    for (const unit of pages) {
      if (unit === entry) continue
      lines.push("", ...this.attrLines(unit, []))
      lines.push(`  defp ${unit.fnName}(assigns) do`, '    ~H"""', unit.heex, '    """', "  end")
    }
    // Module-level literal arrays are kept even when their consumer became a TODO (chart rows computed in React),
    // so the hand-written replacement starts from the original data.
    for (const file of new Set(pages.map(unit => unit.decl.file))) {
      const parsed = this.file(file)
      for (const [name, node] of parsed.consts) {
        if (unwrap(node).type !== "ArrayExpression") continue
        const constant = this.consts.get(this.registerConst(parsed, name, node))!
        if (constant.term) constant.keep = true
      }
    }
    if (this.inlineIcons.size) lines.push("", ...this.inlineIconLines())
    // Emit constants the final code calls (parts that became TODOs may have referenced others) plus kept ones;
    // calls inside comments do not count, so a constant only a TODO mentions is a public `def` (no unused warning).
    const uncommented = (text: string) => text.replace(/<%!--[\s\S]*?--%>/g, "").replace(/^\s*#.*$/gm, "")
    const emitted = new Set<string>()
    let body = uncommented(lines.join("\n"))
    for (let changed = true; changed;) {
      changed = false
      for (const constant of this.consts.values()) {
        if (!constant.term || emitted.has(constant.fn) || !(constant.keep || new RegExp(`\\b${constant.fn}\\(\\)`).test(body))) continue
        emitted.add(constant.fn)
        body += printTerm(constant.term)
        changed = true
      }
    }
    // Keys read on rows of an unknown list are added only when no sample data has them (a key of another list is
    // read on that list's rows).
    const dataKeys = new Set<string>()
    const collectKeys = (term: Term): void => {
      if (term.t === "list") term.items.forEach(collectKeys)
      if (term.t !== "map") return
      for (const [key, value] of term.entries) {
        dataKeys.add(key)
        collectKeys(value)
      }
    }
    for (const constant of this.consts.values()) if (constant.term) collectKeys(constant.term)
    const missingKeys = new Set([...this.accessedKeys].filter(key => !dataKeys.has(key)))
    for (const constant of this.consts.values()) {
      if (!constant.term || !emitted.has(constant.fn)) continue
      const called = new RegExp(`\\b${constant.fn}\\(\\)`).test(body)
      const source = `${constant.file.split("/").slice(-2).join("/")}:${constant.line}`
      lines.push("", called ? `  # Sample data from ${source}; replace with your own data.` : `  # Sample data from ${source}, kept for the source the converter left as TODOs (see the report); replace with your own data.`)
      lines.push(`  ${called ? "defp" : "def"} ${constant.fn} do`, `    ${printTerm(normalizeMaps(constant.term, missingKeys, this.listKeys), 4)}`, "  end")
    }
    lines.push("end", "")

    let code = lines.join("\n")
    // Comments for statements that could not be placed inline go to the top of their template.
    for (const pending of this.pending) {
      const marker = `defp ${pending.ctx.unit.fnName}(assigns) do\n    ~H"""\n`
      const entryMarker = `def ${component ? entry.fnName : "render"}(assigns) do\n    ~H"""\n`
      const comment = `    <%!-- TODO(shadcn-to-liveview): ${stripCodeForComment(pending.reason)} See ${pending.rule}. --%>\n`
      code = code.replace(pending.ctx.unit.entry ? entryMarker : marker, match => match + comment)
    }
    this.pending = []

    const events = component ? [] : [...this.clauses.keys()]
    if (component) {
      for (const handler of this.handlerLines()) if (handler.trim().startsWith("def handle_event(")) events.push(handler.trim())
      if (this.clauses.size) this.notes.push({ file: entry.decl.file, line: 0, message: "Function-component mode: copy the handle_event/3 clauses listed under Events into the LiveView that renders this component." })
    }
    return {
      code,
      todos: [...this.todos].sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line),
      notes: this.notes,
      mapping: [...this.mapping.entries()].map(([react, value]) => ({ react, liveview: value.liveview, count: value.count })).sort((a, b) => b.count - a.count || a.react.localeCompare(b.react)),
      components: pages.filter(unit => unit !== entry).map(unit => `${unit.decl.name} → ${unit.fnName}/1`),
      events,
      assigns: assigns.map(([name]) => name),
      families: [...this.families].sort(),
      files: [...new Set([...this.units.values()].filter(unit => this.referenced(unit)).map(unit => unit.decl.file))],
      skipped: this.completeness(),
      placeholders: this.placeholders,
      viewport: this.viewport,
      assets: this.staticAssets(uncommented(code)),
      entry: this.set.entry,
      label: this.set.label,
      module: this.opts.module,
    }
  }

  /** Root-relative asset paths in the generated code; shadcn templates' originals are on ui.shadcn.com. */
  private staticAssets(code: string): { path: string; url?: string }[] {
    const shadcn = [...this.set.files.keys()].some(file => file.startsWith("/registry/") || /(^|\/)shadcn(\/|$)/.test(file))
      || [...this.set.files.values()].some(source => source.includes("@/registry/"))
    const paths = [...code.matchAll(/"(\/(?!\/)[^"\s#{}?]+\.(?:svg|png|jpe?g|gif|webp|avif|ico|bmp|mp4|webm|mp3|wav|woff2?|pdf))"/gi)].map(match => match[1])
    return [...new Set(paths)].sort().map(path => ({ path, url: shadcn ? `https://ui.shadcn.com${path}` : undefined }))
  }

  private mountAssigns(): [string, string][] {
    const result: [string, string][] = []
    if (this.uiDefaults) result.push(["ui", "%{}"])
    // Connected mounts read the viewport from `params: {is_mobile: ...}`; LiveSocket sends params as query strings
    // (`"true"`), so both forms count. The `.Viewport` hook keeps it current afterwards.
    if (this.viewport && this.opts.mode !== "component") result.push(["is_mobile", `get_connect_params(socket)["is_mobile"] in [true, "true"]`])
    for (const [assign, form] of this.forms) result.push([assign, `to_form(%{}, as: :${form.as})`])
    for (const state of this.states.values()) result.push([state.assign, this.stateInit(state)])
    return result
  }

  /** `load_<table>/1`: DataTable.apply/2 over the table's rows (in memory), assigning the page and the state. */
  private tableLoader(spec: TableSpec): string[] {
    let rows = "[]"
    const data = spec.data && unwrapTs(spec.data)
    const binding = data?.type === "Identifier" ? spec.scope.get(data.name) : undefined
    if (binding?.b === "state") rows = `socket.assigns.${binding.assign}`
    else if (data) {
      try {
        rows = this.serverCode(data as t.Expression, spec.unit, spec.scope)
      } catch (error) {
        if (!(error instanceof Unsupported)) throw error
        this.todos.push({ file: spec.unit.decl.file, line: spec.line, reason: `rows of the TanStack table \`${spec.assign}\` (${error.message}); load them in load_${spec.assign}/1`, rule: rules.tables })
      }
    }
    return [
      `  defp load_${spec.assign}(socket) do`,
      `    {rows, ${spec.assign}} = DataTable.apply(socket.assigns.${spec.assign}, ${rows})`,
      `    assign(socket, ${spec.assign}: ${spec.assign}, ${spec.rowsAssign}: rows)`,
      "  end",
    ]
  }

  private stateInit(state: StateInfo): string {
    if (state.code) return state.code
    if (!state.init) return "nil"
    try {
      return this.serverCode(state.init, state.unit, state.scope)
    } catch (error) {
      if (!(error instanceof Unsupported)) throw error
      this.todos.push({ file: state.unit.decl.file, line: state.line, reason: `initial value of \`${state.assign}\` (${error.message}); set it in mount/3`, rule: rules.state })
      return "nil"
    }
  }

  /** Elixir code for a React expression evaluated outside render (mount/3, handle_event/3): no assigns. */
  private serverCode(node: t.Expression, unit: Unit, scope: Map<string, Binding>): string {
    const ctx: Ctx = { unit, scope: new Map(scope), contexts: new Map(), loopIndexes: [] }
    // Props of the component resolve to its (single) call site.
    const site = unit.callSites.length === 1 ? unit.callSites[0] : undefined
    for (const [local, prop] of unit.props) {
      const value = site?.get(prop.attr)?.code
      if (value && !value.includes("@")) ctx.scope.set(local, { b: "code", code: value })
      else if (prop.defaultNode) ctx.scope.set(local, { b: "local", node: prop.defaultNode, ctx })
    }
    const needs = new Map(unit.needs)
    try {
      const code = this.expr(node, ctx)
      if (/(^|[^\w])@\w/.test(code)) throw new Unsupported("it depends on assigns or props that mount/3 cannot see")
      return code
    } finally {
      unit.needs = needs
    }
  }

  private attrLines(unit: Unit, _assigns: [string, string][]): string[] {
    const lines: string[] = []
    const seen = new Set<string>()
    for (const need of unit.needs.values()) {
      if (seen.has(need.attr)) continue
      seen.add(need.attr)
      lines.push(`  attr :${need.attr}, :${need.kind === "context" ? "map" : "any"}, required: true`)
    }
    for (const [, prop] of unit.props) {
      if (prop.attr === "rest" || prop.attr === "inner_block" || seen.has(prop.attr) || unit.consumedProps.has(prop.attr)) continue
      seen.add(prop.attr)
      let defaultValue = "nil"
      if (prop.defaultNode) {
        try {
          defaultValue = this.expr(prop.defaultNode, { unit, scope: new Map(), contexts: new Map(), loopIndexes: [] })
          if (defaultValue.includes("@") || defaultValue.includes("(")) defaultValue = "nil"
        } catch {
          defaultValue = "nil"
        }
      }
      lines.push(`  attr :${prop.attr}, :any, default: ${defaultValue}`)
    }
    if (unit.hasRest) {
      const include = [...unit.restInclude].sort()
      lines.push(`  attr :rest, :global${include.length ? `, include: ~w(${include.join(" ")})` : ""}`)
    }
    if (unit.keyed) lines.push("  attr :item_key, :string, default: nil")
    if (unit.hasChildren) lines.push("  slot :inner_block")
    return lines
  }

  private handlerLines(): string[] {
    const lines: string[] = []
    const ordered = [...this.clauses.entries()].sort(([a], [b]) => Number(a.startsWith("shadcn:") || a === "control_open") - Number(b.startsWith("shadcn:") || b === "control_open"))
    for (const [event, clause] of ordered) {
      const name = elixirString(event)
      const add = (head: string, body: string) => lines.push(`  def handle_event(${name}, ${head}, socket),`, `    do: {:noreply, ${body}}`, "")
      if (clause.body?.startsWith("form:")) {
        const as = clause.body.slice(5)
        add(`%{"${as}" => params}`, `assign(socket, :${clause.assign}, to_form(params, as: :${as}))`)
        continue
      }
      if (clause.body?.startsWith("submit:")) {
        const as = clause.body.slice(7)
        lines.push(
          `  def handle_event(${name}, %{"${as}" => params}, socket) do`,
          "    # TODO(shadcn-to-liveview): placeholder; validate with a changeset and persist/authenticate (usage-rules/forms.md).",
          `    {:noreply, assign(socket, :${clause.assign}, to_form(params, as: :${as}))}`,
          "  end",
          "",
        )
        continue
      }
      if (clause.body?.startsWith("table:")) {
        const assign = clause.body.slice(6)
        lines.push(
          `  def handle_event(${name}, params, socket) do`,
          `    case DataTable.handle_event(params, socket.assigns.${assign}) do`,
          `      {:query, ${assign}, _opts} -> {:noreply, socket |> assign(:${assign}, ${assign}) |> load_${assign}()}`,
          `      {:ok, ${assign}} -> {:noreply, assign(socket, :${assign}, ${assign})}`,
          "      # Row menu items arrive here (value = the item's value or text). After deleting a row call",
          `      # DataTable.remove_row(${assign}, row_id) and load_${assign}/1 so focus moves to the next row.`,
          `      {:action, _action, _row_id, ${assign}} -> {:noreply, assign(socket, :${assign}, ${assign})}`,
          "    end",
          "  end",
          "",
        )
        continue
      }
      if (clause.body === "viewport") {
        add(`%{"is_mobile" => is_mobile}`, "assign(socket, :is_mobile, is_mobile == true)")
        continue
      }
      if (clause.body) {
        add("params", clause.body)
        continue
      }
      if (clause.uiKey === "open") {
        add(`%{"id" => id}`, "put_ui(socket, id, true)")
        continue
      }
      if (clause.uiKey === "close") {
        add(`%{"id" => id}`, "put_ui(socket, id, false)")
        continue
      }
      if (clause.uiKey === "id") {
        if (clause.styles.has("select")) add(`%{"id" => id, "action" => "select", "value" => value}`, `put_ui(socket, id <> "-value", value)`)
        if (clause.styles.has("select") || clause.styles.has("action")) {
          add(`%{"id" => id, "action" => action}`, `if(action in ["open", "close"], do: put_ui(socket, id, action == "open"), else: socket)`)
        }
        if (clause.styles.has("open")) add(`%{"id" => id, "open" => open}`, "put_ui(socket, id, open)")
        continue
      }
      const assigns = (clause.assign ?? "").split(",").filter(Boolean)
      if (clause.styles.has("push")) {
        const head = `%{${assigns.map(assign => `"${assign}" => ${assign}`).join(", ")}}`
        const failed: string[] = []
        const values = assigns.map(assign => {
          const lookup = clause.lookups?.get(assign)
          if (!lookup) return `${assign}: ${assign}`
          try {
            const list = this.serverCode(lookup.list, lookup.ctx.unit, lookup.ctx.scope)
            return `${assign}: ${lookup.key ? `Enum.find(${list}, &(${atomAccess("&1", lookup.key)} == ${assign}))` : `Enum.at(${list}, ${assign})`} || socket.assigns.${assign}`
          } catch (error) {
            if (!(error instanceof Unsupported)) throw error
            const reason = `\`${event}\` receives the ${lookup.key ? `\`${lookup.key}\`` : "index"} of the selected row, but its list (${error.message}) is not available here; look the row up before assigning \`${assign}\``
            this.todos.push({ file: lookup.file, line: lookup.line, reason, rule: rules.state })
            failed.push(`    # TODO(shadcn-to-liveview): ${reason}.`)
            return `${assign}: ${assign}`
          }
        })
        if (failed.length) lines.push(`  def handle_event(${name}, ${head}, socket) do`, ...failed, `    {:noreply, assign(socket, ${values.join(", ")})}`, "  end", "")
        else add(head, `assign(socket, ${values.join(", ")})`)
      }
      const [assign] = assigns
      if (clause.styles.has("select")) {
        add(`%{"action" => "select", "value" => value}`, `assign(socket, :${assign}, value)`)
        this.uiDefaults = true
        add(`%{"id" => id, "action" => action}`, `if(action in ["open", "close"], do: put_ui(socket, id, action == "open"), else: socket)`)
      }
      if (clause.styles.has("action")) add(`%{"action" => action}`, `if(action in ["open", "close"], do: assign(socket, :${assign}, action == "open"), else: socket)`)
      if (clause.styles.has("open")) add(`%{"open" => open}`, `assign(socket, :${assign}, open)`)
      if (clause.styles.has("value") && clause.keepValue) add(`%{"value" => ""}`, "socket")
      if (clause.styles.has("value")) add(`%{"value" => value}`, `assign(socket, :${assign}, value)`)
    }
    if (!lines.length) return []
    lines.pop()
    return ["  @impl true", ...lines]
  }

  /**
   * Hidden element + colocated hook that pushes `viewport` when the 768px breakpoint (shadcn `useIsMobile`) flips.
   * Pushes only while connected and only when the rendered `data-mobile` differs; `updated`/`reconnected` re-check
   * (a flip during an in-flight push, a reconnect). Pushes go through the library's `sendEvent` helper, whose promise
   * is pre-handled, so a rejected push is never unhandled.
   */
  private viewportHook(): string {
    return [
      `    <div id="${kebab(this.set.label) || "page"}-viewport" phx-hook=".Viewport" data-mobile={to_string(@is_mobile)} hidden></div>`,
      `    <script :type={Phoenix.LiveView.ColocatedHook} name=".Viewport">`,
      "      export default {",
      "        mounted() {",
      '          this.media = window.matchMedia("(max-width: 767px)")',
      "          this.sync = () => {",
      "            if (this.liveSocket.isConnected() && String(this.media.matches) !== this.el.dataset.mobile) {",
      '              this.sendEvent("viewport", {is_mobile: this.media.matches})',
      "            }",
      "          }",
      '          this.media.addEventListener("change", this.sync)',
      "          this.sync()",
      "        },",
      "        updated() {",
      "          this.sync()",
      "        },",
      "        reconnected() {",
      "          this.sync()",
      "        },",
      "        destroyed() {",
      '          this.media.removeEventListener("change", this.sync)',
      "        },",
      sendEventMethod("        "),
      "      }",
      "    </script>",
    ].join("\n")
  }

  /**
   * Source that produced neither output nor a TODO comment: components no converted markup renders, TanStack
   * column definitions, render props, local callbacks, unrendered markup and runtime libraries. The report lists
   * them so it never implies more was converted than the output contains.
   */
  private completeness(): Skipped[] {
    const skipped: Skipped[] = []
    const rendered = new Set<t.Node>([...this.units.values()].filter(unit => this.referenced(unit)).map(unit => unit.decl.node))
    const dataNodes = new Set([...this.consts.values()].flatMap(constant => (constant.term && constant.node ? [constant.node] : [])))
    const files = [...this.set.files.keys()].filter(file => /\.(tsx|jsx)$/.test(file)).map(file => this.file(file))
    const base = (file: string) => file.split("/").pop()!
    const span = (node: t.Node) => `${lineOf(node)}-${node.loc?.end.line ?? lineOf(node)}`
    const isFunction = (node: t.Node | null | undefined): node is t.ArrowFunctionExpression | t.FunctionExpression =>
      node?.type === "ArrowFunctionExpression" || node?.type === "FunctionExpression"
    const eachChild = (node: t.Node, visit: (child: t.Node) => void) => {
      for (const [key, value] of Object.entries(node)) {
        if (key === "loc" || key === "leadingComments" || key === "trailingComments" || key === "innerComments" || key === "extra") continue
        for (const child of Array.isArray(value) ? value : [value]) if (child && typeof child === "object" && typeof child.type === "string") visit(child as t.Node)
      }
    }
    const hasJsx = (node: t.Node): boolean => {
      let found = false
      const visit = (current: t.Node) => {
        if (found) return
        if (isJsx(current)) found = true
        else eachChild(current, visit)
      }
      visit(node)
      return found
    }
    // Where each component name is rendered (`<DragHandle` at data-table.tsx:159), for the hints.
    const usages = new Map<string, string[]>()
    for (const parsed of files) {
      const visit = (node: t.Node) => {
        if (node.type === "JSXOpeningElement") {
          const name = jsxName(node.name)
          usages.set(name, [...(usages.get(name) ?? []), `${base(parsed.file)}:${lineOf(node)}`])
        }
        eachChild(node, visit)
      }
      visit(parsed.ast.program)
    }
    const keyName = (key: t.Node) => (key.type === "Identifier" ? key.name : key.type === "StringLiteral" ? key.value : undefined)
    const stringProp = (object: t.ObjectExpression, name: string) => {
      const property = object.properties.find((entry): entry is t.ObjectProperty => entry.type === "ObjectProperty" && keyName(entry.key) === name)
      return property?.value.type === "StringLiteral" ? property.value.value : undefined
    }
    const renderers = (object: t.ObjectExpression) => object.properties.flatMap(entry =>
      entry.type === "ObjectProperty" && ["header", "cell", "footer", "aggregatedCell"].includes(keyName(entry.key) ?? "") && (isFunction(entry.value) || isJsx(entry.value)) ? [keyName(entry.key)!] : [])

    for (const parsed of files) {
      const components = new Map<t.Node, ComponentDecl>([...parsed.components.values()].map(decl => [decl.node, decl]))
      const push = (node: t.Node, kind: SkippedKind, message: string, rule: string) =>
        skipped.push({ file: parsed.file, line: lineOf(node), endLine: node.loc?.end.line ?? lineOf(node), kind, message, rule })
      const walk = (node: t.Node, stack: t.Node[], component: ComponentDecl | undefined): void => {
        if (this.accounted.has(node) || dataNodes.has(node) || node.type === "ImportDeclaration" || node.type.startsWith("TS")) return
        const parent = stack[stack.length - 1]
        const decl = components.get(node)
        if (decl) {
          if (!rendered.has(node)) {
            const used = (usages.get(decl.name) ?? []).slice(0, 3)
            push(node, "component", `component \`${decl.name}\` (lines ${span(node)}) is never rendered by converted markup${used.length ? ` (used at ${used.join(", ")})` : ""}; nothing of it is in the output`, rules.mapping)
            return
          }
          component = decl
        } else if (isJsx(node) && !this.visited.has(node)) {
          const owner = [...stack].reverse().find(entry => entry.type === "VariableDeclarator" || entry.type === "FunctionDeclaration" || entry.type === "ObjectProperty")
          const ownerName = owner?.type === "VariableDeclarator" && owner.id.type === "Identifier" ? `\`${owner.id.name}\``
            : owner?.type === "FunctionDeclaration" && owner.id ? `\`${owner.id.name}()\``
            : owner?.type === "ObjectProperty" ? `property \`${keyName(owner.key) ?? "?"}\`` : component ? `\`${component.name}\`` : "module scope"
          const name = node.type === "JSXElement" ? `<${jsxName(node.openingElement.name)}>` : "<>"
          push(node, "markup", `markup \`${name}\` (lines ${span(node)}) in ${ownerName} is never rendered`, rules.mapping)
          return
        } else if (node.type === "JSXAttribute" && node.value?.type === "JSXExpressionContainer" && !this.visited.has(node)) {
          const expression = node.value.expression
          if ((isFunction(expression) || isJsx(expression)) && !this.visited.has(expression) && !this.accounted.has(expression)) {
            const element = parent?.type === "JSXOpeningElement" ? `<${jsxName(parent.name)}>` : "an element"
            const prop = node.name.type === "JSXIdentifier" ? node.name.name : node.name.name.name
            if (/^on[A-Z]/.test(prop)) push(node, "callback", `event handler \`${prop}={...}\` on ${element} (lines ${span(node)}) is not converted; bind a phx-*/on_change event and handle it in handle_event/3`, rules.state)
            else push(node, "render-prop", `render prop \`${prop}={...}\` on ${element} (lines ${span(node)}) is not converted`, rules.mapping)
            return
          }
        } else if (node.type === "ObjectExpression" && !this.visited.has(node) && (renderers(node).length || stringProp(node, "accessorKey") || node.properties.some(entry => entry.type === "ObjectProperty" && keyName(entry.key) === "accessorFn"))) {
          const call = parent?.type === "CallExpression" ? parent : undefined
          const accessor = call?.arguments[0]?.type === "StringLiteral" ? call.arguments[0].value : undefined
          const id = stringProp(node, "id") ?? stringProp(node, "accessorKey") ?? accessor ?? "?"
          const parts = renderers(node)
          push(node, "column", this.columnNotes.get(node) ?? `TanStack column \`${id}\` (lines ${span(node)})${parts.length ? ` with ${parts.join("/")} renderer(s)` : ""} is not converted; render its header/cells with table/1 from server-side rows`, rules.tables)
          return
        } else if ((node.type === "FunctionDeclaration" || (node.type === "VariableDeclarator" && isFunction(node.init))) && !this.visited.has(node)) {
          const name = node.type === "FunctionDeclaration" ? node.id?.name : node.id.type === "Identifier" ? node.id.name : undefined
          // Component-local callbacks are behavior that never converts; module helpers matter when they render JSX.
          if (component || hasJsx(node)) {
            push(node, "callback", `${component ? `local function in \`${component.name}\`` : "module function"} \`${name ?? "?"}\` (lines ${span(node)}) is not converted; ${hasJsx(node) ? "render its markup in a function component" : "move its logic to handle_event/3"}`, rules.state)
            return
          }
        }
        eachChild(node, child => walk(child, [...stack, node], component))
      }
      walk(parsed.ast.program, [], undefined)

      for (const statement of parsed.ast.program.body) {
        if (statement.type !== "ImportDeclaration" || statement.importKind === "type") continue
        const rule = libraryRules.find(([pattern]) => pattern.test(statement.source.value))
        const names = statement.specifiers.filter(specifier => specifier.type !== "ImportSpecifier" || specifier.importKind !== "type").map(specifier => specifier.local.name)
          .filter(name => !this.handledImports.has(`${parsed.file}#${name}`))
        if (!rule || !names.length) continue
        push(statement, "library", `\`${statement.source.value}\` (${names.join(", ")}): ${rule[1]}`, rule[2])
      }
    }
    return skipped.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line)
  }

  private inlineIconLines(): string[] {
    const lines = [
      "  # Lucide icons missing from icon/1, inlined from lucide-react; other names fall through to icon/1.",
      "  attr :name, :string, required: true",
      "  attr :class, :any, default: nil",
      "  attr :rest, :global",
      "",
    ]
    for (const [name, svg] of [...this.inlineIcons.entries()].sort()) {
      lines.push(`  defp template_icon(%{name: ${elixirString(name)}} = assigns) do`, '    ~H"""', `    ${svg}`, '    """', "  end", "")
    }
    lines.push("  defp template_icon(assigns) do", '    ~H"""', "    <.icon name={@name} class={@class} {@rest} />", '    """', "  end")
    return lines
  }
}

export function convertTemplate(set: SourceSet, meta: Metadata, opts: ConvertOptions): ConvertResult {
  return new Converter(meta, set, opts).convert()
}
