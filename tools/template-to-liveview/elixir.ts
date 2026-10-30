import { toSnakeCase } from "../generator/names"

export { toSnakeCase }

export function elixirString(value: string): string {
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/#\{/g, "\\#{").replace(/\n/g, "\\n")}"`
}

/** Atom key syntax for a map literal (`title:` or `"foo-bar":`). */
export function atomKey(key: string): string {
  return /^[a-z_][a-zA-Z0-9_]*[?!]?$/.test(key) ? `${key}:` : `${elixirString(key)}:`
}

/** Access syntax for an atom key (`x.title` or `x[:"foo-bar"]`). */
export function atomAccess(base: string, key: string): string {
  return /^[a-z_][a-zA-Z0-9_]*$/.test(key) ? `${base}.${key}` : `${base}[:${elixirString(key)}]`
}

export function kebab(value: string): string {
  return toSnakeCase(value).replace(/_/g, "-").replace(/[^a-z0-9-]/g, "").replace(/-+/g, "-").replace(/^-|-$/g, "")
}

/** Elixir term produced from a JS literal, kept structured so it can be pretty-printed. */
export type Term =
  | { t: "raw"; code: string }
  | { t: "list"; items: Term[] }
  | { t: "map"; entries: [string, Term][] }

export function printTerm(term: Term, indent = 0, width = 98): string {
  const flat = printFlat(term)
  if (indent + flat.length <= width || term.t === "raw") return flat
  const pad = " ".repeat(indent + 2)
  const close = " ".repeat(indent)
  if (term.t === "list") {
    return `[\n${term.items.map(item => pad + printTerm(item, indent + 2, width)).join(",\n")}\n${close}]`
  }
  return `%{\n${term.entries.map(([key, value]) => {
    const flat = printFlat(value)
    // A value that fits after its key stays flat; a broken one opens on the key's line and indents from the key.
    return `${pad}${atomKey(key)} ${indent + 2 + atomKey(key).length + 1 + flat.length <= width ? flat : printTerm(value, indent + 2, width)}`
  }).join(",\n")}\n${close}}`
}

function printFlat(term: Term): string {
  if (term.t === "raw") return term.code
  if (term.t === "list") return `[${term.items.map(printFlat).join(", ")}]`
  return `%{${term.entries.map(([key, value]) => `${atomKey(key)} ${printFlat(value)}`).join(", ")}}`
}

/**
 * Fills keys missing from some maps with `nil`, so `item.key` never raises. Keys are unioned per
 * structural path (`nav_main[].items[]`), across every list at that path, so each list keeps its own
 * key set. Rows of a list in `listKeys` also get the keys templates read on that list's items, and
 * every row map gets the keys in `rowKeys` (keys read where the list is unknown).
 */
export function normalizeMaps(term: Term, rowKeys: Set<string> = new Set(), listKeys: Map<Term, Set<string>> = new Map()): Term {
  const keysByPath = new Map<string, string[]>()
  const add = (path: string, key: string) => {
    const keys = keysByPath.get(path) ?? []
    if (!keys.includes(key)) keys.push(key)
    keysByPath.set(path, keys)
  }
  const collect = (current: Term, path: string): void => {
    if (current.t === "list") {
      current.items.forEach(item => collect(item, `${path}[]`))
      for (const key of listKeys.get(current) ?? []) add(`${path}[]`, key)
    }
    if (current.t !== "map") return
    for (const [key, value] of current.entries) {
      add(path, key)
      collect(value, `${path}.${key}`)
    }
  }
  const fill = (current: Term, path: string): Term => {
    if (current.t === "list") return { t: "list", items: current.items.map(item => fill(item, `${path}[]`)) }
    if (current.t !== "map") return current
    // Only maps inside lists are rows of the same shape; standalone maps keep their own keys.
    const keys = path.endsWith("[]") ? [...new Set([...(keysByPath.get(path) ?? []), ...rowKeys])] : current.entries.map(([key]) => key)
    return {
      t: "map",
      entries: keys.map(key => {
        const value = current.entries.find(([name]) => name === key)?.[1]
        return [key, value ? fill(value, `${path}.${key}`) : { t: "raw", code: "nil" }]
      }),
    }
  }
  collect(term, "")
  return fill(term, "")
}
