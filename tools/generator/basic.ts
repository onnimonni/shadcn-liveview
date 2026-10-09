import { cn } from "cn"
import type { ComponentFunctionSpec } from "../generate"

function generateAttributes(fn: ComponentFunctionSpec): { attrsLines: string[]; isVoid: boolean } {
  const attrsLines: string[] = []

  attrsLines.push(`  attr :class, :string, default: nil`)

  const variantEntries = fn.variants ? Object.entries(fn.variants) : []
  if (variantEntries.length > 0) {
    for (const [varName, varValues] of variantEntries) {
      const defaultVal = fn.defaultVariants?.[varName] ?? Object.keys(varValues)[0] ?? "default"
      attrsLines.push(`  attr :${varName}, :string, default: "${defaultVal}"`)
    }
  }

  if (fn.attrs) {
    for (const a of fn.attrs) {
      if (a.default !== undefined) {
        attrsLines.push(`  attr :${a.name}, :${a.type}, default: ${a.default}`)
      } else {
        attrsLines.push(`  attr :${a.name}, :${a.type}`)
      }
    }
  }

  attrsLines.push(`  attr :rest, :global, include: ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)`)
  if (fn.tag === "textarea") {
    attrsLines.push(`  attr :value, :any, default: nil`)
    attrsLines.push(`  @doc "Native textarea content: a non-nil value overrides the slot; an explicit empty string clears it. Content is escaped and leading newlines are preserved."`)
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
    ? `    assigns = assign(assigns, data_slot: Map.get(assigns.rest, :"data-slot", Map.get(assigns.rest, "data-slot", "button")), rest: Map.drop(assigns.rest, [:"data-slot", "data-slot"]))\n`
    : ""
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
    ~H"""
    <textarea data-slot=${dataSlot}${dataVariantAttrs} class={${classExpr}} {@rest}>{if is_nil(@value), do: render_slot(@inner_block), else: Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end`
    : `  def ${fn.name}(assigns) do
${prepare}    ~H"""
    <${fn.tag}
      data-slot=${dataSlot}${dataVariantAttrs}
      class={${classExpr}}
      {@rest}
    >${fn.extraInnerMarkup ?? ""}
      {render_slot(@inner_block)}
    </${fn.tag}>
    """
  end`


  return [attrsLines.join("\n"), template, variantHelpers.join("\n")].filter(Boolean).join("\n\n")
}
