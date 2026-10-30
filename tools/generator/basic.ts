import { cn } from "cn"
import type { ComponentFunctionSpec } from "../generate"
import { linkAttrs, linkOrElement } from "./links"

const globalAttrs = "accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width".split(" ")
// Table cell attributes beyond the shared inventory; scope and abbr are obsolete on td.
const cellAttrs: Record<string, string[]> = { th: ["abbr", "colspan", "headers", "rowspan", "scope"], td: ["colspan", "headers", "rowspan"] }

// button renders Phoenix.Component.link/1 for navigate, patch or href; anchors for navigate or patch.
function linkMode(fn: ComponentFunctionSpec): "button" | "anchor" | undefined {
  if (fn.name === "button") return "button"
  return fn.tag === "a" ? "anchor" : undefined
}

function globalInclude(fn: ComponentFunctionSpec): string {
  // href is an explicit button attr that selects link mode.
  const names = linkMode(fn) === "button" ? globalAttrs.filter(name => name !== "href") : globalAttrs
  return [...names, ...(cellAttrs[fn.tag] ?? [])].sort().join(" ")
}

function enumAttr(fnName: string, name: string, defaultValue: string, values: string[]): string {
  if (!values.includes(defaultValue)) throw new Error(`${fnName}.${name} default "${defaultValue}" is not one of ${values.join(", ")}`)
  return `  attr :${name}, :string, default: "${defaultValue}", values: ~w(${values.join(" ")})`
}

function generateAttributes(fn: ComponentFunctionSpec): { attrsLines: string[]; isVoid: boolean } {
  const attrsLines: string[] = []

  attrsLines.push(`  attr :class, :any, default: nil`)
  if (fn.tag === "input" || fn.tag === "textarea") {
    attrsLines.push(`  attr :field, Phoenix.HTML.FormField, default: nil`)
  }

  // CVA variant keys are the complete set of styles the class helper can resolve.
  const variantEntries = fn.variants ? Object.entries(fn.variants) : []
  for (const [varName, varValues] of variantEntries) {
    const keys = Object.keys(varValues)
    attrsLines.push(enumAttr(fn.name, varName, fn.defaultVariants?.[varName] ?? keys[0] ?? "default", keys))
  }

  for (const a of fn.attrs ?? []) {
    if (a.values && a.default?.startsWith('"')) attrsLines.push(enumAttr(fn.name, a.name, JSON.parse(a.default), a.values))
    else if (a.default !== undefined) attrsLines.push(`  attr :${a.name}, :${a.type}, default: ${a.default}${a.doc ? `, doc: ${JSON.stringify(a.doc)}` : ""}`)
    else attrsLines.push(`  attr :${a.name}, :${a.type}`)
  }

  const mode = linkMode(fn)
  if (mode) attrsLines.push(...linkAttrs)
  if (mode === "button") {
    attrsLines.push(`  attr :href, :any, default: nil, doc: "Plain link destination; renders \`Phoenix.Component.link/1\` instead of a \`<button>\`."`)
  }
  attrsLines.push(`  attr :rest, :global, include: ~w(${globalInclude(fn)})`)
  if (mode === "button") {
    attrsLines.push(`  @doc "Renders a native \`<button>\`, or \`Phoenix.Component.link/1\` with identical styling when \`navigate\`, \`patch\` or \`href\` is given."`)
  }
  if (fn.tag === "textarea") {
    attrsLines.push(`  attr :value, :any, default: nil`)
    attrsLines.push(`  @doc "Native textarea content: a non-nil value overrides the slot; an explicit empty string clears it. Content is escaped and leading newlines are preserved."`)
  }
  if (fn.tag === "input") {
    attrsLines.push(`  @doc "Accepts a Phoenix.HTML.FormField via field to infer id, name and value. Explicit HTML attributes win; use form_field for labels, help text and used-field errors."`)
  }
  const voidMap: Record<string, true> = { input: true, img: true, hr: true, br: true, meta: true, link: true }
  const isVoid = Boolean(voidMap[fn.tag])
  if (!isVoid) {
    attrsLines.push(`  slot :inner_block, required: false`)
  }
  return { attrsLines, isVoid }
}

function generateVariantClasses(fn: ComponentFunctionSpec): { classExpr: string; variantHelpers: string[] } {
  const variantEntries = fn.variants ? Object.entries(fn.variants) : []
  let classExpr = `"${fn.baseClasses.replace(/"/g, '\\"')}"`
  const variantHelpers: string[] = []

  if (variantEntries.length === 2) {
    const [var1, map1] = variantEntries[0]
    const [var2, map2] = variantEntries[1]
    const def1 = fn.defaultVariants?.[var1] ?? Object.keys(map1)[0] ?? "default"
    const def2 = fn.defaultVariants?.[var2] ?? Object.keys(map2)[0] ?? "default"
    classExpr = `[${fn.name}_classes(@${var1}, @${var2}), @class]`
    const styles = Object.entries(map1).map(([key, classes1]) => {
      const sizes = Object.entries(map2).map(([size, classes2]) =>
        `${JSON.stringify(size)} => ${JSON.stringify(cn(fn.baseClasses, classes1, classes2))}`)
      return `    ${JSON.stringify(key)} => %{${sizes.join(", ")}}`
    })
    const fallback = JSON.stringify(cn(fn.baseClasses, map1[def1] || "", map2[def2] || ""))
    variantHelpers.push(`  @${fn.name}_styles %{\n${styles.join(",\n")}\n  }\n\n  defp ${fn.name}_classes(${var1}, ${var2}) do\n    @${fn.name}_styles\n    |> Map.get(${var1} || "${def1}", %{})\n    |> Map.get(${var2} || "${def2}", ${fallback})\n  end`)
  } else if (variantEntries.length === 1) {
    const [var1, map1] = variantEntries[0]
    const def1 = fn.defaultVariants?.[var1] ?? Object.keys(map1)[0] ?? "default"
    classExpr = `[${fn.name}_classes(@${var1}), @class]`
    const styles = Object.entries(map1).map(([key, value]) =>
      `    ${JSON.stringify(key)} => ${JSON.stringify(cn(fn.baseClasses, value))}`)
    const fallback = JSON.stringify(cn(fn.baseClasses, map1[def1] || ""))
    variantHelpers.push(`  @${fn.name}_styles %{\n${styles.join(",\n")}\n  }\n\n  defp ${fn.name}_classes(${var1}) do\n    Map.get(@${fn.name}_styles, ${var1} || "${def1}", ${fallback})\n  end`)
  } else {
    classExpr = `[${classExpr}, @class]`
  }
  classExpr = `classes(${classExpr})`
  return { classExpr, variantHelpers }
}

export function generateBasicFunction(fn: ComponentFunctionSpec): string {
  const { attrsLines, isVoid } = generateAttributes(fn)
  const { classExpr, variantHelpers } = generateVariantClasses(fn)
  let dataVariantAttrs = ""
  if (fn.hasDataVariant) {
    dataVariantAttrs += ` data-variant={@variant}`
  }
  if (fn.hasDataSize) {
    dataVariantAttrs += ` data-size={@size}`
  }
  if (fn.staticAttrs && fn.staticAttrs.length > 0) {
    dataVariantAttrs += ` ${fn.staticAttrs.join(" ")}`
  }

  const dataSlot = fn.name === "button" ? "{@data_slot}" : `"${fn.slotName}"`
  const prepare = fn.name === "button"
    ? `    assigns = assign(assigns, data_slot: Map.get(assigns.rest, :"data-slot", Map.get(assigns.rest, "data-slot", "button")), rest: assigns.rest |> Map.drop([:"data-slot", "data-slot"]) |> trigger_rest!(Map.get(assigns.rest, "id"), "button"))\n`
    : fn.tag === "input" ? "    assigns = ShadcnLiveview.Form.bind(assigns, :input)\n" : ""
  const template = isVoid
    ? `  def ${fn.name}(assigns) do
${prepare}    ~H"""
    <${fn.tag}
      data-slot=${dataSlot}${dataVariantAttrs}
      class={${classExpr}}
      {@rest}
    />
    """
  end`
    : fn.tag === "textarea"
    ? `  def ${fn.name}(assigns) do
    assigns = ShadcnLiveview.Form.bind(assigns, :textarea)
    ~H"""
    <textarea data-slot=${dataSlot}${dataVariantAttrs} class={${classExpr}} {@rest}>{if is_nil(@value), do: render_slot(@inner_block), else: Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end`
    : `  def ${fn.name}(assigns) do
${prepare}    ~H"""
${elementMarkup(fn, `
      data-slot=${dataSlot}${dataVariantAttrs}
      class={${classExpr}}
      {@rest}
    `, `
      ${fn.innerMarkup ?? "{render_slot(@inner_block)}"}
    `)}
    """
  end`


  return [attrsLines.join("\n"), template, variantHelpers.join("\n")].filter(Boolean).join("\n\n")
}

function elementMarkup(fn: ComponentFunctionSpec, attrs: string, body: string): string {
  const mode = linkMode(fn)
  if (!mode) return `    <${fn.tag}${attrs}>${body}</${fn.tag}>`
  return linkOrElement({
    open: fn.tag, close: fn.tag, attrs, body,
    ...(mode === "button" ? { linkAttrs: " href={@href}", condition: "@navigate || @patch || @href" } : {}),
  })
}
