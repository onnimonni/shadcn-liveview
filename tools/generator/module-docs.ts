import type { ComponentSpec } from "../generate"

// One-line purposes for families rendered by the generic generators; converter
// families write their own module docs next to their state contracts.
const purposes: Record<string, string> = {
  "alert": "Displays a callout for user attention.",
  "aspect-ratio": "Displays content within a desired width/height ratio.",
  "attachment": "Displays a file attachment with media, title, description and actions.",
  "avatar": "An image element with a fallback for representing a user.\n\n  As with Radix, `avatar_fallback` shows until `avatar_image` has loaded (and again after a load\n  error or a new `src`), and the image is shown only once loaded. A bundled script mirrors the\n  load into the image's `data-status` (`loading`/`loaded`/`error`) and the library CSS applies it,\n  so render both; no id or hook is needed.",
  "badge": "Displays a badge or a component that looks like a badge.",
  "breadcrumb": "Displays the path to the current resource as a hierarchy of links.",
  "bubble": "Chat message bubbles with grouping, content and reactions.",
  "button": "Displays a button or a component that looks like a button.",
  "button-group": "Groups related buttons with shared borders and orientation.",
  "card": "Displays a card with header, content and footer.",
  "direction": "Sets the text direction (`ltr`/`rtl`) for a subtree.",
  "empty": "Displays an empty state with media, title, description and actions.",
  "field": "Composes labels, controls, descriptions and errors into accessible form fields.",
  "input": "Displays a native form input, optionally bound to a `Phoenix.HTML.FormField`.",
  "input-group": "Adds addons, buttons and helper text around inputs and textareas.",
  "item": "A flexible row for displaying media, content and actions.",
  "kbd": "Displays keyboard input such as shortcuts.",
  "label": "Renders an accessible label associated with a control.",
  "marker": "Inline status or section marker with an icon and content.",
  "message": "Chat message layout with avatar, header, content and footer.",
  "native-select": "A styled native `<select>` with options and option groups.",
  "pagination": "Page navigation with previous, next and numbered links.",
  "progress": "Displays the completion progress of a task as a bar.",
  "scroll-area": "Scrollable region styled like Radix ScrollArea.",
  "separator": "Visually or semantically separates content.",
  "skeleton": "Placeholder shown while content is loading.",
  "sonner": "Toast notifications pushed from the server with `push_event/3`.",
  "spinner": "Animated loading indicator.",
  "table": "A responsive table with header, body, footer, rows and cells.",
  "textarea": "Displays a native textarea, optionally bound to a `Phoenix.HTML.FormField`.",
}

export interface ModuleDocSource {
  docsUrl: string
  example: string
}

export function componentNames(source: string): string[] {
  return [...source.matchAll(/^  def ([a-z_0-9?!]+)\(assigns\)/gm)].map(match => match[1])
    .filter((name, index, names) => names.indexOf(name) === index)
}

export function basicModuleDoc(spec: ComponentSpec, functionsCode: string, source: ModuleDocSource): string {
  const purpose = purposes[spec.name]
  if (!purpose) throw new Error(`Missing module purpose for "${spec.name}" in tools/generator/module-docs.ts`)
  if (source.example.includes('"""')) throw new Error(`Example for "${spec.name}" cannot contain a heredoc delimiter`)
  const functions = componentNames(functionsCode).map(name => `\`${name}/1\``).join(", ")
  const example = source.example.split("\n").map(line => `  ${line}`.trimEnd()).join("\n")
  return `  @moduledoc ~S"""
  ${purpose}

  Upstream: ${source.docsUrl}

  Components: ${functions}.

  Example (locally authored, rendered by the SSR parity fixtures):

  \`\`\`heex
${example}
  \`\`\`
  """`
}

// Generic attribute docs; payload shapes stay in each module's docs.
function attrDoc(name: string, type: string, rest: string, siblings: Set<string>, hooked: boolean): string | undefined {
  if (name === "id" && rest.includes("required: true")) {
    return hooked
      ? "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."
      : "Stable, unique DOM id, constant across renders."
  }
  if (name === "field" && type === "Phoenix.HTML.FormField") {
    return "Form field such as `@form[:email]`; supplies id, name and value. Explicit attributes win."
  }
  if (name === "class" && type === ":any") return "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."
  if (name === "target") return "Event target such as `@myself`; equivalent to `phx-target` on the root."
  const controlled = name.match(/^default_(\w+)$/)?.[1]
  if (controlled && siblings.has(controlled)) {
    return `Uncontrolled initial \`${controlled}\`; ignored once \`${controlled}\` is supplied.`
  }
  const event = name.match(/^on_(\w+)$/)?.[1]?.replaceAll("_", " ")
  if (event && type === "JS") return `\`Phoenix.LiveView.JS\` commands to run on ${event}.`
  if (event && type === ":string") {
    const optional = /default: nil\b/.test(rest) ? " `nil` pushes no event." : ""
    return `LiveView event name pushed on ${event}; the payload is described in the module docs.${optional}`
  }
  return undefined
}

const attrLine = /^(\s*)attr :(\w+), ([\w.:]+)(.*)$/

export function documentAttrs(source: string): string {
  const lines = source.split("\n")
  const hooked = source.includes("phx-hook")
  let block: number[] = []
  const flush = () => {
    const siblings = new Set(block.map(index => lines[index].match(attrLine)![2]))
    for (const index of block) {
      const [, indent, name, type, rest] = lines[index].match(attrLine)!
      if (rest.includes("doc:")) continue
      const doc = attrDoc(name, type, rest, siblings, hooked)
      if (doc) lines[index] = `${indent}attr :${name}, ${type}${rest}, doc: ${JSON.stringify(doc)}`
    }
    block = []
  }
  lines.forEach((line, index) => {
    if (/^\s*(def|defp|defmacro)\s/.test(line)) flush()
    else if (attrLine.test(line) && !/\b(do|,)\s*$/.test(line)) block.push(index)
  })
  flush()
  return lines.join("\n")
}
