import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { parseFamily, statements } from "../generator/component-index"

// Component API read from the library's own Elixir sources (the same parser that builds
// usage-rules/components.md), so conversions always target the installed version.

export interface AttrMeta {
  name: string
  type: string
  required: boolean
  defaultValue?: string
  values?: string[]
}

export interface SlotMeta {
  name: string
  required: boolean
  attrs: Set<string>
}

export interface FnMeta {
  name: string
  family: string
  module: string
  attrs: Map<string, AttrMeta>
  slots: Map<string, SlotMeta>
  restInclude: Set<string>
  hasRest: boolean
}

export interface Metadata {
  libDir: string
  functions: Map<string, FnMeta>
  icons: Set<string>
  iconAliases: Map<string, string>
}

// Phoenix.Component `:global` attributes accepted by every `attr :rest, :global`.
const globalAttrs: Record<string, true> = Object.fromEntries(
  ("accesskey autocapitalize autofocus class contenteditable dir draggable enterkeyhint exportparts hidden id inert " +
    "inputmode is itemid itemprop itemref itemscope itemtype lang nonce part popover role slot spellcheck style tabindex " +
    "title translate").split(" ").map(name => [name, true]),
)
const globalPrefixes = ["aria-", "data-", "phx-"]

/** Accepted by any `attr :rest, :global` without an `include:` entry. */
export function isGlobalAttr(attr: string): boolean {
  return !!globalAttrs[attr] || globalPrefixes.some(prefix => attr.startsWith(prefix))
}

export function acceptsAttr(fn: FnMeta, attr: string): boolean {
  if (fn.attrs.has(attr)) return true
  if (!fn.hasRest) return false
  return isGlobalAttr(attr) || fn.restInclude.has(attr)
}

function supplement(source: string): Map<string, { slots: Map<string, SlotMeta>; include: Set<string>; hasRest: boolean }> {
  const result = new Map<string, { slots: Map<string, SlotMeta>; include: Set<string>; hasRest: boolean }>()
  let slots = new Map<string, SlotMeta>()
  let include = new Set<string>()
  let hasRest = false
  for (const statement of statements(source)) {
    if (statement.startsWith("attr :rest, :global")) {
      hasRest = true
      const words = statement.match(/include: ~w\(([^)]*)\)/)
      if (words) for (const word of words[1].trim().split(/\s+/)) include.add(word)
    } else if (statement.startsWith("slot :")) {
      const [, name] = statement.match(/^slot :(\w+)/)!
      const head = statement.split(/\sdo\b/)[0]
      const attrs = new Set([...statement.matchAll(/\battr :(\w+)/g)].map(match => match[1]))
      slots.set(name, { name, required: /\brequired: true\b/.test(head), attrs })
    } else if (/^defp? \w+\(/.test(statement)) {
      const [, kind, name, args] = statement.match(/^(defp?) (\w+)\(([^)]*)/)!
      if (kind === "def" && /\bassigns\s*$/.test(args) && !result.has(name)) result.set(name, { slots, include, hasRest })
      slots = new Map()
      include = new Set()
      hasRest = false
    }
  }
  return result
}

function iconTables(source: string): { icons: Set<string>; aliases: Map<string, string> } {
  const classes = source.match(/@icon_classes %\{([\s\S]*?)\n  \}/)
  const aliases = source.match(/@icon_aliases %\{([\s\S]*?)\n  \}/)
  return {
    icons: new Set([...(classes?.[1] ?? "").matchAll(/"([a-z0-9-]+)" =>/g)].map(match => match[1])),
    aliases: new Map([...(aliases?.[1] ?? "").matchAll(/"([a-z0-9-]+)" => "([a-z0-9-]+)"/g)].map(match => [match[1], match[2]])),
  }
}

/** Locates `lib/shadcn_liveview` next to this script (Hex package `priv/`, repo `tools/...`) or in the app's deps. */
export function findLibDir(explicit?: string): string {
  const here = path.dirname(fileURLToPath(import.meta.url))
  const candidates = [
    explicit,
    path.resolve(here, "../lib/shadcn_liveview"),
    path.resolve(here, "../../lib/shadcn_liveview"),
    path.resolve("deps/shadcn_liveview/lib/shadcn_liveview"),
    path.resolve("lib/shadcn_liveview"),
  ].filter((candidate): candidate is string => !!candidate)
  for (const candidate of candidates) {
    if (fs.existsSync(path.join(candidate, "components", "button.ex"))) return candidate
  }
  throw new Error(`Cannot find shadcn_liveview component sources (tried ${candidates.join(", ")}); pass --lib <deps/shadcn_liveview/lib/shadcn_liveview>.`)
}

export function loadMetadata(libDir = findLibDir()): Metadata {
  const functions = new Map<string, FnMeta>()
  let icons = new Set<string>()
  let iconAliases = new Map<string, string>()
  const componentsDir = path.join(libDir, "components")
  const sources = fs.readdirSync(componentsDir).filter(file => file.endsWith(".ex")).sort()
    .map(file => ({ file: path.join(componentsDir, file), family: file.replace(/\.ex$/, "") }))
  sources.push({ file: path.join(libDir, "form.ex"), family: "form" }, { file: path.join(libDir, "data_table.ex"), family: "data_table" })
  for (const { file, family } of sources) {
    const source = fs.readFileSync(file, "utf8")
    const module = source.match(/^defmodule ([\w.]+) do/m)?.[1] ?? ""
    const index = parseFamily(family, module, source, "-")
    const extra = supplement(source)
    for (const fn of index.functions) {
      const more = extra.get(fn.name)
      functions.set(fn.name, {
        name: fn.name,
        family,
        module,
        attrs: new Map(fn.attrs.map(attr => [attr.name, attr])),
        slots: more?.slots ?? new Map(),
        restInclude: more?.include ?? new Set(),
        hasRest: more?.hasRest ?? false,
      })
    }
    if (family === "icon") ({ icons, aliases: iconAliases } = iconTables(source))
  }
  return { libDir, functions, icons, iconAliases }
}

/** Lucide component name (`ChevronRightIcon`, `Trash2`) → kebab name accepted by `icon/1`, or undefined. */
export function lucideName(meta: Metadata, component: string): string | undefined {
  const kebab = lucideKebab(component)
  const canonical = meta.iconAliases.get(kebab) ?? kebab
  return meta.icons.has(canonical) ? canonical : undefined
}

export function lucideKebab(component: string): string {
  return component
    .replace(/^Lucide/, "")
    .replace(/Icon$/, "")
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1-$2")
    .replace(/([a-zA-Z])([0-9])/g, "$1-$2")
    .toLowerCase()
}
