import fs from "node:fs/promises"
import path from "node:path"
import ts from "typescript"
import { fixtures } from "./fixtures"
import { cn } from "cn"
import { generateIcons } from "./icons"
import { generateComponent as linked } from "./converters/linked"
import { generateComponent as modals } from "./converters/modals"
import { generateComponent as popups } from "./converters/popups"
import { generateComponent as command } from "./converters/command"
import { generateComponent as calendar } from "./converters/calendar"
import { generateComponent as layout } from "./converters/layout"
import { generateComponent as chart } from "./converters/chart"
import { generateComponent as conversation } from "./converters/conversation"
import { generateComponent as selections } from "./converters/selections"
import { generateComponent as controls } from "./converters/controls"
import { generateComponent as toggle } from "./converters/toggle"

export interface ComponentSpec {
  name: string
  moduleName: string
  functions: ComponentFunctionSpec[]
}

export interface ComponentFunctionSpec {
  name: string
  tag: string
  slotName: string
  baseClasses: string
  variants?: Record<string, Record<string, string>>
  defaultVariants?: Record<string, string>
  attrs?: { name: string; type: string; default?: string }[]
  extraInnerMarkup?: string
  hasDataVariant?: boolean
  hasDataSize?: boolean
  staticAttrs?: string[]
}

function toSnakeCase(str: string): string {
  return str
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1_$2")
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/[-\s]+/g, "_")
    .toLowerCase()
}

function toPascalCase(str: string): string {
  return str
    .split(/[-_]/)
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
    .join("")
}

function cleanStringLiteral(str: string): string {
  let s = str.trim()
  while (
    (s.startsWith('"') && s.endsWith('"')) ||
    (s.startsWith("'") && s.endsWith("'")) ||
    (s.startsWith("`") && s.endsWith("`"))
  ) {
    s = s.slice(1, -1).trim()
  }
  return s.replace(/\s+/g, " ").trim()
}

function resolveHtmlTag(origName: string, rawTag: string): string {
  const lowerName = origName.toLowerCase()
  const lowerTag = rawTag.toLowerCase()

  const passthrough: Record<string, true> = {
    dialog: true,
    alertdialog: true,
    sheet: true,
    drawer: true,
    popover: true,
    tooltip: true,
    tooltipprovider: true,
    hovercard: true,
    contextmenu: true,
    dropdownmenu: true,
    directionprovider: true,
    messagescrollerprovider: true,
  }
  if (passthrough[lowerName]) return "slot_only"
  if (lowerName === "inputgroupinput") return "input"
  if (lowerName === "inputgrouptextarea") return "textarea"

  if (lowerName.includes("group") || lowerName.includes("button_group") || lowerName.includes("buttongroup")) {
    return "div"
  }

  if (lowerName === "avatar") return "span"
  if (lowerName === "avatarimage") return "img"
  if (lowerName === "avatarfallback") return "span"
  if (lowerName === "spinner") return "svg"

  if (lowerName.includes("input") && !lowerName.includes("group") && !lowerName.includes("otp")) return "input"
  if (lowerName.includes("textarea")) return "textarea"
  if (lowerName.includes("label")) return "label"
  if (lowerName.includes("tableheader")) return "thead"
  if (lowerName.includes("tablebody")) return "tbody"
  if (lowerName.includes("tablerow")) return "tr"
  if (lowerName.includes("tablehead")) return "th"
  if (lowerName.includes("tablecell")) return "td"
  if (lowerName.includes("tablefooter")) return "tfoot"
  if (lowerName.includes("tablecaption")) return "caption"
  if (lowerName === "table") return "table"
  if (lowerName === "kbd") return "kbd"
  if (lowerName === "breadcrumb") return "nav"
  if (lowerName === "breadcrumblist") return "ol"
  if (lowerName.includes("breadcrumbitem") || lowerName.includes("breadcrumbseparator")) return "li"
  if (lowerName.includes("link") && !lowerName.includes("input")) return "a"
  if (lowerName.includes("breadcrumbpage") || lowerName.includes("badge")) return "span"
  if (lowerName.includes("navigationmenulist") || lowerName.includes("navigation_menu_list")) return "ul"
  if (lowerName.includes("navigationmenuitem") || lowerName.includes("navigation_menu_item")) return "li"
  if (lowerName.includes("paginationcontent") || lowerName.includes("pagination_content")) return "ul"
  if (lowerName.includes("paginationitem") || lowerName.includes("pagination_item")) return "li"
  if (lowerName === "questionnaireitem" || lowerName === "questionnaire_item") return "fieldset"
  if (lowerName.includes("card") || lowerName === "alert" || lowerName === "alerttitle" || lowerName === "alertdescription" || lowerName.includes("itemtitle") || lowerName.includes("item_title")) return "div"
  if (lowerName === "emptytitle" || lowerName === "emptydescription") return "div"
  if (lowerName === "attachmenttitle" || lowerName === "attachmentdescription") return "span"
  if (lowerName.endsWith("title")) return "h2"
  if (lowerName.endsWith("description")) return "p"
  if (
    lowerName.includes("trigger") ||
    lowerName === "button" ||
    lowerName.endsWith("_button") ||
    lowerName.includes("action") ||
    lowerName.includes("cancel") ||
    lowerName.includes("close") ||
    lowerName === "toggle"
  ) {
    return "button"
  }
  if (lowerTag === "span" || lowerTag === "a" || lowerTag === "nav" || lowerTag === "ol" || lowerTag === "li") {
    return lowerTag
  }
  return "div"
}

export function generateElixirModule(spec: ComponentSpec): string {
  for (const convert of [linked, modals, popups, command, calendar, layout, chart, conversation, selections, controls, toggle]) {
    const component = convert(spec)
    if (component !== undefined) return component
  }
  const funcsCode = spec.functions
    .map(generateFunction)
    .join("\n\n")
  const helpersImport = funcsCode.includes("classes(") ? "  import ShadcnLiveview.Helpers\n" : ""

  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc false
  use Phoenix.Component
${helpersImport}
${funcsCode}
end
`
}

function generateFunction(fn: ComponentFunctionSpec): string {
  if (fn.tag === "slot_only") {
    return `  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def ${fn.name}(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end`
  }

  if (fn.name === "table") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def table(assigns) do
    ~H"""
    <div data-slot="table-container" class="relative w-full overflow-x-auto">
      <table
        data-slot="table"
        class={["w-full caption-bottom text-sm", @class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end`
  }
  if (fn.name === "aspect_ratio") {
    return `  attr :ratio, :float, default: 1.7777777777777777
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def aspect_ratio(assigns) do
    padding = (1.0 / (assigns.ratio || (16.0 / 9.0))) * 100.0
    assigns = assign(assigns, :padding, padding)
    ~H"""
    <div style={"position:relative;width:100%;padding-bottom:#{@padding}%"} data-radix-aspect-ratio-wrapper="">
      <div
        data-slot="aspect-ratio"
        style="position:absolute;top:0;right:0;bottom:0;left:0"
        class={[@class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end`
  }

  if (fn.name === "breadcrumb_separator") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_separator(assigns) do
    ~H"""
    <li
      data-slot="breadcrumb-separator"
      role="presentation"
      aria-hidden="true"
      class={["[&>svg]:size-3.5", @class]}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" class="cn-rtl-flip" />
    </li>
    """
  end`
  }

  
  if (fn.name === "spinner") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def spinner(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={classes(["lucide lucide-loader-circle lucide-loader-2 size-4 animate-spin", @class])}
      data-slot="spinner"
      role="status"
      aria-label="Loading"
      {@rest}
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
    """
  end`
  }
  

  

  if (fn.name === "native_select") {
    return `  @doc """
  Native select with a wrapper and decorative icon. \`class\` styles the wrapper;
  \`size\` is "default" or "sm". Native attributes (name, id, disabled,
  multiple, required, form, autocomplete and ARIA attributes) go on the select.

  \`value\` (controlled initial selection) takes precedence over \`default_value\`.
  Both accept a scalar or, for multiple selection, a list. Use
  \`:let={selection}\` on the inner slot and \`selected={value in selection}\`
  on each option to apply this normalized string list, including inside optgroups.

      <.native_select :let={selection} name="fruit" default_value="pear">
        <.native_select_option value="apple" selected={"apple" in selection}>Apple</.native_select_option>
        <.native_select_option value="pear" selected={"pear" in selection}>Pear</.native_select_option>
      </.native_select>

  Without a selection prop, the browser selects its native default.
  Subsequent user selection and form submission are handled by the native element;
  LiveView callers can supply phx-change and update value on subsequent renders.
  """
  attr :class, :string, default: nil
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :value, :any, default: nil
  attr :default_value, :any, default: nil
  attr :rest, :global, include: ~w(name disabled multiple required form autofocus autocomplete)
  slot :inner_block, required: false

  def native_select(assigns) do
    selection = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value
    assigns = assign(assigns, :selection, Enum.map(List.wrap(selection), &to_string/1))
    ~H"""
    <div
      class={classes(["group/native-select relative w-fit has-[select:disabled]:opacity-50", @class])}
      data-slot="native-select-wrapper"
      data-size={@size}
    >
      <select
        data-slot="native-select"
        data-size={@size}
        class="h-8 w-full min-w-0 appearance-none rounded-lg border border-input bg-transparent py-1 pr-8 pl-2.5 text-sm transition-colors outline-none select-none selection:bg-primary selection:text-primary-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 data-[size=sm]:h-7 data-[size=sm]:rounded-[min(var(--radius-md),10px)] data-[size=sm]:py-0.5 dark:bg-input/30 dark:hover:bg-input/50 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40"
        {@rest}
      >{render_slot(@inner_block, @selection)}</select>
      <ShadcnLiveview.Components.Icon.icon
        name="chevron-down"
        class="pointer-events-none absolute top-1/2 right-2.5 size-4 -translate-y-1/2 text-muted-foreground select-none"
        aria-hidden="true"
        data-slot="native-select-icon"
      />
    </div>
    """
  end`
  }

  if (fn.name === "native_select_option" || fn.name === "native_select_opt_group") {
    const option = fn.name === "native_select_option"
    const tag = option ? "option" : "optgroup"
    return `  @doc """
  Native ${tag}; forwards ${option ? "value, selected, disabled and label" : "label and disabled"}.
  ${option ? "Set selected from the native_select slot selection list when using value/default_value." : "Nested options can use the enclosing native_select slot selection list."}
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(${option ? "value selected disabled label" : "label disabled"})
  slot :inner_block, required: false

  def ${fn.name}(assigns) do
    ~H"""
    <${tag}
      data-slot="${option ? "native-select-option" : "native-select-optgroup"}"
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >{render_slot(@inner_block)}</${tag}>
    """
  end`
  }

  if (fn.name === "progress") {
    return `  @doc """
  Progress matching the upstream wrapper: \`value\` controls only the indicator's
  visual percentage (nil/absent means zero). It is not passed to the Radix root,
  so both root and indicator remain indeterminate and omit aria-valuenow.
  \`max\` sets root/indicator data-max and aria-valuemax, defaulting to 100
  unless it is a positive number; it does not scale the visual percentage.
  \`class\` styles the root; global/ARIA attributes are forwarded to the root.
  """
  attr :value, :any, default: nil
  attr :max, :any, default: 100
  attr :class, :string, default: nil
  attr :rest, :global

  def progress(assigns) do
    max = if is_number(assigns.max) and assigns.max > 0, do: assigns.max, else: 100
    max = if is_float(max) and max == trunc(max), do: trunc(max), else: max
    offset = 100 - (assigns.value || 0)
    offset = if is_float(offset) and offset == trunc(offset), do: trunc(offset), else: offset
    assigns = assign(assigns, max: max, offset: offset)
    ~H"""
    <div
      data-slot="progress"
      role="progressbar"
      aria-valuemax={@max}
      aria-valuemin="0"
      data-state="indeterminate"
      data-max={@max}
      class={classes(["relative flex h-1 w-full items-center overflow-x-hidden rounded-full bg-muted", @class])}
      {@rest}
    >
      <div
        data-slot="progress-indicator"
        data-state="indeterminate"
        data-max={@max}
        class="size-full flex-1 bg-primary transition-all"
        style={"transform:translateX(-#{@offset}%)"}
      />
    </div>
    """
  end`
  }

  

  

  

  

  


  
  if (fn.name === "pagination") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination(assigns) do
    ~H"""
    <nav
      role="navigation"
      aria-label="pagination"
      data-slot="pagination"
      class={classes(["mx-auto flex w-full justify-center", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end`
  }

  if (fn.name === "pagination_link") {
    return `  attr :is_active, :boolean, default: false
  attr :size, :string, default: "icon"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_link(assigns) do
    ~H"""
    <a
      data-slot="pagination-link"
      data-variant={if @is_active, do: "outline", else: "ghost"}
      data-size={@size}
      aria-current={if @is_active, do: "page"}
      data-active={if @is_active, do: "true"}
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
        if(@is_active, do: "border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50", else: "border-transparent hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50"),
        if(@size == "default", do: "h-8 gap-1.5 px-2.5", else: "size-8"),
        @class
      ])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end`
  }

  if (fn.name === "pagination_previous") {
    return `  attr :text, :string, default: "Previous"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_previous(assigns) do
    ~H"""
    <a
      aria-label="Go to previous page"
      data-slot="pagination-link"
      data-variant="ghost"
      data-size="default"
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 pl-1.5! has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        @class
      ])}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-left" data-icon="inline-start" class="cn-rtl-flip" />
      <span class="hidden sm:block">{@text}</span>
    </a>
    """
  end`
  }

  if (fn.name === "pagination_next") {
    return `  attr :text, :string, default: "Next"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_next(assigns) do
    ~H"""
    <a
      aria-label="Go to next page"
      data-slot="pagination-link"
      data-variant="ghost"
      data-size="default"
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 pr-1.5! has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        @class
      ])}
      {@rest}
    >
      <span class="hidden sm:block">{@text}</span>
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" data-icon="inline-end" class="cn-rtl-flip" />
    </a>
    """
  end`
  }

  if (fn.name === "scroll_area") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  @doc "Renders the initial Radix scroll-area viewport and scrollbar-hiding CSS. Scrollbars are absent in SSR."
  def scroll_area(assigns) do
    ~H"""
    <div
      data-slot="scroll-area"
      dir="ltr"
      class={classes(["relative", @class])}
      style="position:relative;--radix-scroll-area-corner-width:0px;--radix-scroll-area-corner-height:0px"
      {@rest}
    >
      <style><%= Phoenix.HTML.raw("[data-radix-scroll-area-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-scroll-area-viewport]::-webkit-scrollbar{display:none}") %></style>
      <div
        data-radix-scroll-area-viewport=""
        data-slot="scroll-area-viewport"
        class="size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1"
        style="overflow-x:hidden;overflow-y:hidden"
      >
        <div style="min-width:100%;display:table">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end`
  }

  

  if (fn.name === "sonner" || fn.name === "toaster") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def ${fn.name}(assigns) do
    ~H"""
    <section
      aria-label="Notifications alt+T"
      tabindex="-1"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      data-react-aria-top-layer="true"
      {@rest}
    />
    """
  end`
  }

  

  

  

  
  

  

  

  

  

  

  

  

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
  const voidMap: Record<string, true> = { input: true, img: true, hr: true, br: true, meta: true, link: true }
  const isVoid = Boolean(voidMap[fn.tag])
  if (!isVoid) {
    attrsLines.push(`  slot :inner_block, required: false`)
  }

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

export function parseComponentAST(fileName: string, code: string): ComponentSpec {
  const moduleName = toPascalCase(fileName)
  const sf = ts.createSourceFile(`${fileName}.tsx`, code, ts.ScriptTarget.Latest, true)

  interface CvaSpec {
    baseClasses: string
    variants?: Record<string, Record<string, string>>
    defaultVariants?: Record<string, string>
  }
  const cvaByFunction: Record<string, CvaSpec> = {}

  for (const stmt of sf.statements) {
    if (ts.isVariableStatement(stmt)) {
      for (const decl of stmt.declarationList.declarations) {
        if (ts.isIdentifier(decl.name) && decl.initializer && ts.isCallExpression(decl.initializer)) {
          if (decl.initializer.expression.getText(sf) === "cva") {
            const varName = decl.name.text
            const targetName = toSnakeCase(varName.replace(/Variants$/, ""))

            let cvaBase = ""
            let cvaVars: Record<string, Record<string, string>> | undefined
            let cvaDefs: Record<string, string> | undefined

            const arg0 = decl.initializer.arguments[0]
            if (arg0 && (ts.isStringLiteral(arg0) || ts.isNoSubstitutionTemplateLiteral(arg0))) {
              cvaBase = arg0.text.replace(/\s+/g, " ").trim()
            }
            const arg1 = decl.initializer.arguments[1]
            if (arg1 && ts.isObjectLiteralExpression(arg1)) {
              for (const prop of arg1.properties) {
                if (ts.isPropertyAssignment(prop) && ts.isIdentifier(prop.name)) {
                  if (prop.name.text === "variants" && ts.isObjectLiteralExpression(prop.initializer)) {
                    cvaVars = {}
                    for (const vProp of prop.initializer.properties) {
                      if (ts.isPropertyAssignment(vProp) && ts.isIdentifier(vProp.name)) {
                        const vName = vProp.name.text
                        cvaVars[vName] = {}
                        if (ts.isObjectLiteralExpression(vProp.initializer)) {
                          for (const opt of vProp.initializer.properties) {
                            if (ts.isPropertyAssignment(opt)) {
                              const optKey = opt.name.getText(sf).replace(/^["'`]|["'`]$/g, "")
                              if (ts.isStringLiteral(opt.initializer) || ts.isNoSubstitutionTemplateLiteral(opt.initializer)) {
                                cvaVars[vName][optKey] = opt.initializer.text.replace(/\s+/g, " ").trim()
                              }
                            }
                          }
                        }
                      }
                    }
                  } else if (prop.name.text === "defaultVariants" && ts.isObjectLiteralExpression(prop.initializer)) {
                    cvaDefs = {}
                    for (const dProp of prop.initializer.properties) {
                      if (ts.isPropertyAssignment(dProp) && ts.isIdentifier(dProp.name)) {
                        const dName = dProp.name.text
                        if (ts.isStringLiteral(dProp.initializer)) {
                          cvaDefs[dName] = dProp.initializer.text
                        }
                      }
                    }
                  }
                }
              }
            }
            cvaByFunction[targetName] = { baseClasses: cvaBase, variants: cvaVars, defaultVariants: cvaDefs }
          }
        }
      }
    }
  }

  // 2. Discover exported functions and components via AST
  const functions: ComponentFunctionSpec[] = []
  const seenNames = new Set<string>()

  function inspectNode(node: ts.Node, name: string) {
    const fnSnakeName = toSnakeCase(name)
    if (seenNames.has(fnSnakeName)) return
    seenNames.add(fnSnakeName)

    const isPrimary = name.toLowerCase() === fileName.replace(/-/g, "").toLowerCase()
    const primaryName = toSnakeCase(fileName)
    // A family's first CVA may belong to a child (e.g. EmptyMedia), not its root.
    const matchedCva = cvaByFunction[fnSnakeName] || (isPrimary ? cvaByFunction[primaryName] : undefined)

    let foundSlot = fnSnakeName.replace(/_/g, "-")
    let foundClasses = matchedCva?.baseClasses || ""
    let foundTag = "div"
    let hasDataVariant = false
    let hasDataSize = false
    const staticAttrsList: string[] = []
    const openings: (ts.JsxOpeningElement | ts.JsxSelfClosingElement)[] = []
    function collectJsx(n: ts.Node) {
      if (ts.isJsxElement(n)) openings.push(n.openingElement)
      else if (ts.isJsxSelfClosingElement(n)) openings.push(n)
      ts.forEachChild(n, collectJsx)
    }
    collectJsx(node)
    const hasAttribute = (opening: ts.JsxOpeningElement | ts.JsxSelfClosingElement, name: string) =>
      opening.attributes.properties.some(prop => ts.isJsxAttribute(prop) && prop.name.getText(sf) === name)
    const opening = openings.find(candidate => candidate.attributes.properties.some(prop =>
      ts.isJsxAttribute(prop) && prop.name.getText(sf) === "data-slot" &&
      prop.initializer && ts.isStringLiteral(prop.initializer) && prop.initializer.text === foundSlot))
      ?? openings.find(candidate => hasAttribute(candidate, "className"))
      ?? openings.find(candidate => hasAttribute(candidate, "data-slot") || hasAttribute(candidate, "role"))

    if (opening) {
      foundTag = opening.tagName.getText(sf)
      for (const prop of opening.attributes.properties) {
        if (!ts.isJsxAttribute(prop)) continue
        const attrName = prop.name.getText(sf)
        if (attrName === "data-slot" && prop.initializer && ts.isStringLiteral(prop.initializer)) {
          foundSlot = prop.initializer.text
        }
        if (attrName === "data-variant") hasDataVariant = true
        if (attrName === "data-size") hasDataSize = true
        if (attrName === "role" && prop.initializer && ts.isStringLiteral(prop.initializer)) {
          staticAttrsList.push(`role="${prop.initializer.text}"`)
        }
        if (attrName !== "className" || !prop.initializer) continue
        const expr = ts.isJsxExpression(prop.initializer) ? prop.initializer.expression : prop.initializer
        if (!expr) continue
        if (ts.isCallExpression(expr)) {
          if (expr.arguments[0] && (ts.isStringLiteral(expr.arguments[0]) || ts.isNoSubstitutionTemplateLiteral(expr.arguments[0]))) {
            foundClasses = expr.arguments
              .filter((arg): arg is ts.StringLiteral | ts.NoSubstitutionTemplateLiteral =>
                ts.isStringLiteral(arg) || ts.isNoSubstitutionTemplateLiteral(arg))
              .map(arg => arg.text).join(" ").replace(/\s+/g, " ").trim()
          }
        } else if (ts.isStringLiteral(expr) || ts.isNoSubstitutionTemplateLiteral(expr)) {
          foundClasses = expr.text.replace(/\s+/g, " ").trim()
        }
      }
    }

    let finalTag = resolveHtmlTag(name, foundTag)

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
    functions.push({
      name: fnSnakeName,
      tag: finalTag,
      slotName: foundSlot,
      baseClasses: foundClasses,
      variants: matchedCva?.variants,
      defaultVariants: matchedCva?.defaultVariants,
      attrs: specialAttrs,
      hasDataVariant,
      hasDataSize,
      staticAttrs: staticAttrsList,
    })
  }

  for (const stmt of sf.statements) {
    if (ts.isFunctionDeclaration(stmt) && stmt.name) {
      inspectNode(stmt, stmt.name.text)
    } else if (ts.isVariableStatement(stmt)) {
      for (const decl of stmt.declarationList.declarations) {
        if (ts.isIdentifier(decl.name) && decl.initializer) {
          const varName = decl.name.text
          if (varName.endsWith("Variants")) continue
          inspectNode(decl.initializer, varName)
        }
      }
    }
  }

  // Ensure default function if none found
  if (functions.length === 0) {
    functions.push({
      name: toSnakeCase(fileName),
      tag: resolveHtmlTag(fileName, "div"),
      slotName: fileName,
      baseClasses,
      variants,
      defaultVariants,
    })
  }

  return {
    name: fileName,
    moduleName,
    functions,
  }
}




export async function generateAllComponents(): Promise<void> {
  const outDir = path.resolve("lib/shadcn_liveview/components")
  await fs.mkdir(outDir, { recursive: true })
  await generateIcons()

  const files = (await fs.readdir("vendor/shadcn/ui")).filter((f) => f.endsWith(".tsx")).sort()
  console.log(`Found ${files.length} vendored UI component files.`)
  const coveredFamilies = new Set(fixtures.map(fixture => fixture.family ?? fixture.name))
  const missingFamilies = files.map(file => file.replace(/\.tsx$/, "")).filter(family => !coveredFamilies.has(family))
  if (missingFamilies.length) throw new Error(`Missing family fixtures: ${missingFamilies.join(", ")}`)
  const names = fixtures.map(fixture => fixture.name)
  if (new Set(names).size !== names.length) throw new Error("Duplicate fixture names")

  const moduleNames: string[] = []
  const inheritedClasses = new Map<string, string>()
  for (const [control, target] of [["input", "input_group_input"], ["textarea", "input_group_textarea"], ["label", "field_label"]]) {
    const source = await fs.readFile(path.join("vendor/shadcn/ui", control + ".tsx"), "utf8")
    const controlSpec = parseComponentAST(control, source)
    inheritedClasses.set(target, controlSpec.functions.find((fn) => fn.name === control)!.baseClasses)
  }

  for (const f of files) {
    const compName = f.replace(/\.tsx$/, "")
    const code = await fs.readFile(path.join("vendor/shadcn/ui", f), "utf8")
    const spec = parseComponentAST(compName, code)
    // Compound controls compose upstream primitive styles before local overrides.
    for (const fn of spec.functions) {
      const inherited = inheritedClasses.get(fn.name)
      if (inherited) fn.baseClasses = cn(inherited, fn.baseClasses)
    }
    const elixirCode = generateElixirModule(spec)
    const outPath = path.join(outDir, `${compName.replace(/-/g, "_")}.ex`)
    await fs.writeFile(outPath, elixirCode, "utf8")
    moduleNames.push(spec.moduleName)
  }

  // Generate umbrella module lib/shadcn_liveview.ex
  const importsList = moduleNames.map((m) => `      import ShadcnLiveview.Components.${m}`).join("\n")

  const umbrellaCode = `defmodule ShadcnLiveview do
  @moduledoc """
  Shadcn component library for Phoenix LiveView.
  Provides all 61 Radix-Nova shadcn components as Phoenix function components.

  Run \`mix assets.build\` before SSR previews. The CSS pipeline bundles imports and
  embeds fonts, then compiles Tailwind utilities; asset failures stop parity runs.

  Run \`bun run generate\` to convert the pinned upstream source and format emitted
  Elixir/HEEx. Complex components use dedicated structural converters with explicit
  attrs, slots, stable caller IDs and controlled state; no hidden rendering context.
  Register \`hooks\` exported from the compiled colocated manifest in your LiveSocket.

  \`mix quality\` enforces formatter checks, warning-free HEEx/Elixir compilation,
  strict Credo and the LiveView assign/change-tracking rules on generated modules.
  \`bun run test\` regenerates components, runs that quality gate, behavior tests and
  SSR comparison. Every fixture and every covered family must pass; failures exit
  nonzero. IDs may differ only for generated identities; reference graphs remain strict.

  Start \`SHADCN_PREVIEW=1 mix run --no-halt\` and visit
  \`http://127.0.0.1:4000/live-preview/accordion\` to exercise real LiveView patches
  and colocated hooks. \`bun run test:parity\` compares all 309 initial-render cases.
  SSR parity alone does not prove every prop or browser interaction.
  """

  defmacro __using__(_opts) do
    quote do
      import ShadcnLiveview.Components.Icon
${importsList}
    end
  end
end
`
  await fs.writeFile("lib/shadcn_liveview.ex", umbrellaCode, "utf8")
  console.log(`Generated lib/shadcn_liveview.ex with ${moduleNames.length} component modules.`)

  // Generate lib/shadcn_liveview/gallery.ex
  const galleryCases = fixtures
    .map((f) => {
      const indented = f.heex
        .split("\n")
        .map((l) => "    " + l)
        .join("\n")
      return `  def render_fixture("${f.name}") do\n    assigns = %{}\n    ~H"""\n${indented}\n    """\n  end`
    })
    .join("\n\n")
  const liveGalleryCases = fixtures.map((f) => {
    const indented = (f.liveHeex ?? f.heex).split("\n").map((line) => "    " + line).join("\n")
    return `  def live_fixture(%{fixture: "${f.name}"} = assigns) do\n    ~H"""\n${indented}\n    """\n  end`
  }).join("\n\n")

  const namesList = fixtures.map((f) => `"${f.name}"`).join(", ")
  const galleryCode = `defmodule ShadcnLiveview.Gallery do
  @moduledoc false
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  def names, do: [${namesList}]

  def render_html(name) do
    case render_fixture(name) do
      nil -> nil
      rendered -> Safe.to_iodata(rendered) |> IO.iodata_to_binary()
    end
  end

  def dump_all do
    names()
    |> Enum.map(fn name -> {name, render_html(name)} end)
    |> Map.new()
    |> Jason.encode!()
  end

${galleryCases}

  def render_fixture(_), do: nil

  attr :fixture, :string, required: true
  attr :state, :map, required: true
  @doc "Renders a connected fixture using the caller's tracked LiveView assigns."

${liveGalleryCases}

  def live_fixture(%{fixture: fixture}),
    do: raise(ArgumentError, "Unknown component fixture: #{inspect(fixture)}")
end
`
  await fs.writeFile("lib/shadcn_liveview/gallery.ex", galleryCode, "utf8")
  console.log(`Generated lib/shadcn_liveview/gallery.ex with ${fixtures.length} fixture renderers.`)
}

async function runCli(): Promise<void> {
  const isDirect = process.argv[1]?.endsWith("generate.tsx") || process.argv[1]?.endsWith("generate.ts")
  if (isDirect) {
    await generateAllComponents()
  }
}

runCli().catch((err) => {
  console.error("Component generation failed:", err)
  process.exit(1)
})
