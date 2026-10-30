import type * as t from "@babel/types"

// TanStack Table (v8 `useReactTable` + `ColumnDef[]`, v9 `useTable` + `createColumnHelper`) →
// ShadcnLiveview.DataTable. Pure AST helpers; convert.ts resolves names and emits HEEx.

export const tableHooks = /^(useReactTable|useTable)$/
export const tanstackSource = /^@tanstack\/(react-)?table/

/** One column definition: an object literal, or the options of `columnHelper.accessor/display(...)`. */
export interface TableColumn {
  /** Options object (header/cell/...); the completeness check reports it when not converted. */
  node: t.ObjectExpression
  field: string
  accessor: boolean
  header?: t.Expression
  cell?: t.Expression
  enableHiding: boolean
  enableSorting: boolean
}

/** Groups of `table.*` calls and the HEEx part that replaces the JSX around them. */
export type TablePartKind = "grid" | "pagination" | "columns" | "search"

const groups: Record<string, TablePartKind> = {
  getHeaderGroups: "grid", getRowModel: "grid", getFooterGroups: "grid",
  getFilteredSelectedRowModel: "pagination", getFilteredRowModel: "pagination", getSelectedRowModel: "pagination",
  getPageCount: "pagination", getRowCount: "pagination", getPrePaginationRowModel: "pagination",
  previousPage: "pagination", nextPage: "pagination", firstPage: "pagination", lastPage: "pagination",
  setPageIndex: "pagination", setPageSize: "pagination", getCanPreviousPage: "pagination", getCanNextPage: "pagination",
  getAllColumns: "columns", getAllLeafColumns: "columns",
}

export function unwrapTs(node: t.Node): t.Node {
  let current = node
  while (current.type === "TSAsExpression" || current.type === "TSSatisfiesExpression" || current.type === "TSNonNullExpression" || current.type === "ParenthesizedExpression") current = current.expression
  return current
}

export function property(object: t.ObjectExpression, name: string): t.ObjectProperty | undefined {
  return object.properties.find((entry): entry is t.ObjectProperty =>
    entry.type === "ObjectProperty" && !entry.computed && (entry.key.type === "Identifier" ? entry.key.name : entry.key.type === "StringLiteral" ? entry.key.value : undefined) === name)
}

export function propertyValue(object: t.ObjectExpression, name: string): t.Expression | undefined {
  const found = property(object, name)
  return found ? (unwrapTs(found.value) as t.Expression) : undefined
}

function memberName(callee: t.Node): string | undefined {
  return (callee.type === "MemberExpression" || callee.type === "OptionalMemberExpression") && !callee.computed && callee.property.type === "Identifier" ? callee.property.name : undefined
}

/** Key of the first `<object>.key` read below `root` (`row.slug` in `getRowId: (row) => row.slug`). */
export function findMember(root: t.Node, object: string): string | undefined {
  let key: string | undefined
  walk(root, node => {
    if (!key && (node.type === "MemberExpression" || node.type === "OptionalMemberExpression") && node.object.type === "Identifier" && node.object.name === object) key = memberName(node)
  })
  return key
}

/** The column list behind `columns`: an array literal or `columnHelper.columns([...])`. */
export function columnArray(node: t.Node): t.ArrayExpression | undefined {
  const value = unwrapTs(node)
  if (value.type === "ArrayExpression") return value
  if (value.type === "CallExpression" && memberName(value.callee) === "columns" && value.arguments[0]) return columnArray(value.arguments[0])
  return undefined
}

/** Column definitions, or undefined when any entry is not a recognisable column (groups, spreads, helpers). */
export function parseColumns(array: t.ArrayExpression): TableColumn[] | undefined {
  const columns: TableColumn[] = []
  for (const element of array.elements) {
    if (!element || element.type === "SpreadElement") return undefined
    const value = unwrapTs(element)
    let options: t.Node | undefined
    let field: string | undefined
    let accessor = false
    if (value.type === "ObjectExpression") {
      options = value
      const accessorKey = propertyValue(value, "accessorKey")
      field = accessorKey?.type === "StringLiteral" ? accessorKey.value : undefined
      accessor = !!field || !!property(value, "accessorFn")
    } else if (value.type === "CallExpression" && (memberName(value.callee) === "accessor" || memberName(value.callee) === "display")) {
      accessor = memberName(value.callee) === "accessor"
      const [first, second] = value.arguments
      options = accessor ? second : first
      if (accessor && first?.type === "StringLiteral") field = first.value
    }
    if (!options || options.type !== "ObjectExpression") return undefined
    const id = propertyValue(options, "id")
    field ??= id?.type === "StringLiteral" ? id.value : undefined
    if (!field || property(options, "columns")) return undefined
    // TanStack's enableHiding/enableSorting default to true.
    const enabled = (name: string) => {
      const flag = propertyValue(options as t.ObjectExpression, name)
      return flag?.type !== "BooleanLiteral" || flag.value
    }
    columns.push({
      node: options,
      field,
      accessor,
      header: propertyValue(options, "header"),
      cell: propertyValue(options, "cell"),
      enableHiding: enabled("enableHiding"),
      enableSorting: enabled("enableSorting"),
    })
  }
  return columns
}

/** Visits every AST node below `root` with the chain of enclosing JSX elements. */
export function walk(root: t.Node, visit: (node: t.Node, elements: t.JSXElement[]) => void, elements: t.JSXElement[] = []): void {
  visit(root, elements)
  const inner = root.type === "JSXElement" ? [...elements, root] : elements
  for (const [key, value] of Object.entries(root)) {
    if (key === "loc" || key === "leadingComments" || key === "trailingComments" || key === "innerComments" || key === "extra") continue
    for (const child of Array.isArray(value) ? value : [value]) {
      if (child && typeof child === "object" && typeof (child as t.Node).type === "string") walk(child as t.Node, visit, inner)
    }
  }
}

/** True when `root` calls any of `names` (`fn()` or `x.fn()`). */
export function callsAny(root: t.Node, names: string[]): boolean {
  let found = false
  walk(root, node => {
    if (found || (node.type !== "CallExpression" && node.type !== "OptionalCallExpression")) return
    const callee = node.callee
    const name = callee.type === "Identifier" ? callee.name : memberName(callee)
    if (name && names.includes(name)) found = true
  })
  return found
}

/** First JSX element below `root` (or `root` itself) satisfying `test`. */
export function findElement(root: t.Node, test: (element: t.JSXElement) => boolean): t.JSXElement | undefined {
  let found: t.JSXElement | undefined
  walk(root, node => {
    if (!found && node.type === "JSXElement" && test(node)) found = node
  })
  return found
}

/** Visible static text of a JSX tree (string children and `{"literal"}` containers). */
export function staticText(root: t.Node): string {
  const parts: string[] = []
  walk(root, node => {
    if (node.type === "JSXText") parts.push(node.value)
    else if (node.type === "JSXExpressionContainer" && node.expression.type === "StringLiteral") parts.push(node.expression.value)
  })
  return parts.join(" ").replace(/\s+/g, " ").trim()
}

export interface TableUse {
  kind: TablePartKind
  elements: t.JSXElement[]
  /** `table.getColumn("email")` for column filter inputs. */
  field?: string
}

/** Every `<tableVar>.method(...)` / `<tableVar>.state.pagination` use inside `root`, grouped by part. */
export function tableUses(root: t.Node, tableVar: string): TableUse[] {
  const uses: TableUse[] = []
  const seen = new Set<t.Node>()
  walk(root, (node, elements) => {
    if ((node.type !== "MemberExpression" && node.type !== "OptionalMemberExpression") || seen.has(node)) return
    if (node.object.type !== "Identifier" || node.object.name !== tableVar || node.computed || node.property.type !== "Identifier") return
    seen.add(node)
    const method = node.property.name
    if (method === "getColumn") {
      uses.push({ kind: "search", elements, field: columnFilterField(root, node) })
    } else if (groups[method]) {
      uses.push({ kind: groups[method], elements })
    } else if (method === "state" || method === "getState") {
      uses.push({ kind: "pagination", elements })
    }
  })
  return uses
}

/** `table.getColumn("email")?.getFilterValue()` → "email" (undefined for other getColumn uses). */
function columnFilterField(root: t.Node, getColumn: t.Node): string | undefined {
  let field: string | undefined
  walk(root, node => {
    if (field || (node.type !== "CallExpression" && node.type !== "OptionalCallExpression")) return
    const callee = node.callee
    if ((callee.type !== "MemberExpression" && callee.type !== "OptionalMemberExpression") || callee.property.type !== "Identifier") return
    if (!/^(get|set)FilterValue$/.test(callee.property.name)) return
    const inner = unwrapTs(callee.object)
    if ((inner.type === "CallExpression" || inner.type === "OptionalCallExpression") && inner.callee === getColumn && inner.arguments[0]?.type === "StringLiteral") {
      field = inner.arguments[0].value
    }
  })
  return field
}

/** Deepest element shared by every chain (undefined when a chain is empty or they diverge at the root). */
export function commonElement(chains: t.JSXElement[][]): t.JSXElement | undefined {
  if (!chains.length) return undefined
  let common: t.JSXElement | undefined
  for (let depth = 0; ; depth++) {
    const candidate = chains[0][depth]
    if (!candidate || chains.some(chain => chain[depth] !== candidate)) return common
    common = candidate
  }
}
