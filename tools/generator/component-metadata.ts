import type { ComponentFunctionSpec } from "../generate"
import type { CvaSpec } from "./cva"

export function applyComponentMetadata(
  fnSnakeName: string,
  finalTag: string,
  hasDataSize: boolean,
  hasDataVariant: boolean,
  matchedCva: CvaSpec | undefined,
  staticAttrsList: string[],
): { tag: string; attrs: ComponentFunctionSpec["attrs"] } {
  const specialAttrs: { name: string; type: string; default?: string }[] = []
  if (fnSnakeName === "attachment") {
    specialAttrs.push({ name: "state", type: "string", default: '"done"' })
    staticAttrsList.push('data-state={@state} data-orientation={@orientation}')
  }
  if (fnSnakeName === "input_group_addon") {
    staticAttrsList.push('data-align={@align}')
  }
  if (fnSnakeName === "field") {
    staticAttrsList.push('data-orientation={@orientation}')
  }
  if (fnSnakeName === "chart_container") {
    specialAttrs.push({ name: "config", type: "map", default: "%{}" })
  }
  if (fnSnakeName === "aspect_ratio") {
    specialAttrs.push({ name: "ratio", type: "float", default: "1.0" })
  }
  const openComponents: Record<string, true> = {
    dialog: true,
    alert_dialog: true,
    sheet: true,
    drawer: true,
    dropdown_menu: true,
    popover: true,
    tooltip: true,
    hover_card: true,
    select: true,
    collapsible: true,
  }
  if (openComponents[fnSnakeName]) {
    specialAttrs.push({ name: "open", type: "boolean", default: "false" })
  }
  if (["accordion", "tabs", "radio_group"].includes(fnSnakeName)) {
    specialAttrs.push({ name: "default_value", type: "string", default: "nil" })
    if (fnSnakeName === "accordion") {
      specialAttrs.push({ name: "type", type: "string", default: '"single"' })
    }
  }
  if (hasDataSize && !matchedCva?.variants?.size) {
    specialAttrs.push({ name: "size", type: "string", default: '"default"' })
  }
  if (hasDataVariant && !matchedCva?.variants?.variant) {
    specialAttrs.push({ name: "variant", type: "string", default: '"default"' })
  }
  if (fnSnakeName === "bubble") {
    specialAttrs.push({ name: "align", type: "string", default: '"start"' })
    staticAttrsList.push('data-align={@align}')
  }
  if (fnSnakeName === "separator") {
    specialAttrs.push({ name: "orientation", type: "string", default: '"horizontal"' })
    staticAttrsList.push('data-orientation={@orientation} role="none"')
  }
  if (fnSnakeName === "message") {
    specialAttrs.push({ name: "align", type: "string", default: '"start"' })
    staticAttrsList.push('data-align={@align}')
  }
  if (fnSnakeName === "field_set") {
    finalTag = "fieldset"
  }
  if (fnSnakeName === "item_description") {
    finalTag = "p"
  }
  if (fnSnakeName === "breadcrumb") {
    staticAttrsList.push('aria-label="breadcrumb"')
  }
  if (fnSnakeName === "breadcrumb_page") {
    staticAttrsList.push('aria-disabled="true" aria-current="page"')
  }
  if (fnSnakeName === "navigation_menu_list") {
    finalTag = "ul"
    staticAttrsList.push('data-orientation="horizontal" dir="ltr"')
  }
  if (fnSnakeName === "questionnaire") {
    finalTag = "form"
  }
  if (fnSnakeName === "toggle") {
    specialAttrs.push({ name: "pressed", type: "boolean", default: "false" })
    staticAttrsList.push('type="button" aria-pressed={to_string(@pressed)} data-state={if @pressed, do: "on", else: "off"}')
  }
  return { tag: finalTag, attrs: specialAttrs }
}
