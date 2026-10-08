import fs from "node:fs/promises"
import path from "node:path"
import ts from "typescript"
import { fixtures } from "./fixtures"
import { cn } from "cn"

export interface ComponentSpec {
  name: string
  moduleName: string
  functions: ComponentFunctionSpec[]
  hook?: {
    name: string
    js: string
  }
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
  const primaryName = spec.name.replace(/-/g, "_")
  const funcsCode = spec.functions
    .map((fn) => generateFunction(fn, spec.hook, fn.name === primaryName))
    .join("\n\n")
  const helpersImport = spec.name.replace(/-/g, "_") !== "aspect_ratio" ? "  import ShadcnLiveview.Helpers\n" : ""

  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc false
  use Phoenix.Component
${helpersImport}
${funcsCode}
end
`
}

function generateFunction(
  fn: ComponentFunctionSpec,
  hook?: { name: string; js: string },
  isPrimary = false
): string {
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

  if (fn.name === "accordion_trigger") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_trigger(assigns) do
    ~H"""
    <h3 class="flex" data-orientation="vertical" data-state="open">
      <button
        type="button"
        data-slot="accordion-trigger"
        data-orientation="vertical"
        data-state="open"
        aria-expanded="true"
        aria-disabled="true"
        data-radix-collection-item=""
        id="radix-id"
        aria-controls="radix-id"
        class={["group/accordion-trigger relative flex flex-1 items-start justify-between rounded-lg border border-transparent py-2.5 text-left text-sm font-medium transition-all outline-none hover:underline focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:after:border-ring disabled:pointer-events-none disabled:opacity-50 **:data-[slot=accordion-trigger-icon]:ml-auto **:data-[slot=accordion-trigger-icon]:size-4 **:data-[slot=accordion-trigger-icon]:text-muted-foreground", @class]}
        {@rest}
      >
        {render_slot(@inner_block)}
        <ShadcnLiveview.Components.Icon.icon name="chevron-down" data-slot="accordion-trigger-icon" class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:hidden" />
        <ShadcnLiveview.Components.Icon.icon name="chevron-up" data-slot="accordion-trigger-icon" class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:inline hidden" />
      </button>
    </h3>
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
  if (fn.name === "checkbox") {
    return `  attr :checked, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def checkbox(assigns) do
    ~H"""
    <button
      type="button"
      role="checkbox"
      aria-checked={to_string(@checked)}
      data-state={if @checked, do: "checked", else: "unchecked"}
      value="on"
      data-slot="checkbox"
      class={classes(["peer relative flex size-4 shrink-0 items-center justify-center rounded-[4px] border border-input transition-colors outline-none group-has-disabled/field:opacity-50 group-has-[:focus-visible]/field-label:ring-0 group-has-[:focus-visible]/field-label:not-data-checked:border-input after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 aria-invalid:aria-checked:border-primary dark:bg-input/30 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:border-primary data-checked:bg-primary data-checked:text-primary-foreground group-has-[:focus-visible]/field-label:data-checked:border-primary dark:data-checked:bg-primary", @class])}
      {@rest}
    ><%= if @checked do %><span data-slot="checkbox-indicator" class="grid place-content-center text-current transition-none [&>svg]:size-3.5"><ShadcnLiveview.Components.Icon.icon name="check" class="size-3.5" /></span><% end %></button><input
      type="checkbox"
      aria-hidden="true"
      tabindex="-1"
      style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
      value="on"
      checked={@checked}
    />
    """
  end`
  }

  if (fn.name === "switch") {
    return `  attr :checked, :boolean, default: false
  attr :size, :string, default: "default"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def switch(assigns) do
    ~H"""
    <button
      type="button"
      role="switch"
      aria-checked={to_string(@checked)}
      data-state={if @checked, do: "checked", else: "unchecked"}
      value="on"
      data-slot="switch"
      data-size={@size}
      class={classes(["peer group/switch relative inline-flex shrink-0 items-center rounded-full border border-transparent transition-all outline-none group-has-[:focus-visible]/field-label:border-transparent group-has-[:focus-visible]/field-label:ring-0 after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 data-[size=default]:h-[18.4px] data-[size=default]:w-[32px] data-[size=sm]:h-[14px] data-[size=sm]:w-[24px] dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:bg-primary data-unchecked:bg-input dark:data-unchecked:bg-input/80 data-disabled:cursor-not-allowed data-disabled:opacity-50", @class])}
      {@rest}
    ><span
        data-slot="switch-thumb"
        data-state={if @checked, do: "checked", else: "unchecked"}
        class="pointer-events-none block rounded-full bg-background ring-0 transition-transform group-data-[size=default]/switch:size-4 group-data-[size=sm]/switch:size-3 group-data-[size=default]/switch:data-checked:translate-x-[calc(100%-2px)] group-data-[size=sm]/switch:data-checked:translate-x-[calc(100%-2px)] dark:data-checked:bg-primary-foreground group-data-[size=default]/switch:data-unchecked:translate-x-0 group-data-[size=sm]/switch:data-unchecked:translate-x-0 dark:data-unchecked:bg-foreground"
      /></button><input
      type="checkbox"
      aria-hidden="true"
      tabindex="-1"
      style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
      value="on"
      checked={@checked}
    />
    """
  end`
  }

  if (fn.name === "progress") {
    return `  attr :value, :integer, default: 0
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def progress(assigns) do
    state = if (assigns.value || 0) == 100, do: "complete", else: "loading"
    assigns = assign(assigns, :state, state)
    ~H"""
    <div
      data-slot="progress"
      role="progressbar"
      aria-valuemax="100"
      aria-valuemin="0"
      aria-valuenow={to_string(@value || 0)}
      data-state={@state}
      class={classes(["relative flex h-1 w-full items-center overflow-x-hidden rounded-full bg-muted", @class])}
      {@rest}
    >
      <div
        data-slot="progress-indicator"
        data-state={@state}
        class="size-full flex-1 bg-primary transition-all"
        style={"transform:translateX(-#{100 - (@value || 0)}%)"}
      />
    </div>
    """
  end`
  }

  if (fn.name === "dialog_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="dialog-overlay"
      class="fixed inset-0 isolate z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"
      style="pointer-events:auto"
    />
    <div
      role="dialog"
      id="radix-id"
      data-state="open"
      data-slot="dialog-content"
      tabindex="-1"
      class={classes(["fixed top-1/2 left-1/2 z-50 grid w-full max-w-[calc(100%-2rem)] -translate-x-1/2 -translate-y-1/2 gap-4 rounded-xl bg-popover p-4 text-sm text-popover-foreground ring-1 ring-foreground/10 duration-100 outline-none sm:max-w-sm data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
      <button type="button" data-slot="dialog-close" data-variant="ghost" data-size="icon-sm" class="group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium text-sm whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg absolute top-2 right-2">
        <ShadcnLiveview.Components.Icon.icon name="x" />
        <span class="sr-only">Close</span>
      </button>
    </div>
    """
  end`
  }

  if (fn.name === "alert_dialog_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def alert_dialog_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="alert-dialog-overlay"
      class="fixed inset-0 z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"
      style="pointer-events:auto"
    />
    <div
      role="alertdialog"
      id="radix-id"
      data-state="open"
      data-slot="alert-dialog-content"
      data-size="default"
      tabindex="-1"
      class={classes(["group/alert-dialog-content fixed top-1/2 left-1/2 z-50 grid w-full -translate-x-1/2 -translate-y-1/2 gap-4 rounded-xl bg-popover p-4 text-popover-foreground ring-1 ring-foreground/10 duration-100 outline-none data-[size=default]:max-w-xs data-[size=sm]:max-w-xs data-[size=default]:sm:max-w-sm data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "alert_dialog_action") {
    return `  attr :variant, :string, default: "default"
  attr :size, :string, default: "default"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def alert_dialog_action(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="alert-dialog-action"
      data-variant={@variant}
      data-size={@size}
      class={classes(["group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end`
  }

  if (fn.name === "alert_dialog_cancel") {
    return `  attr :variant, :string, default: "outline"
  attr :size, :string, default: "default"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def alert_dialog_cancel(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="alert-dialog-cancel"
      data-variant={@variant}
      data-size={@size}
      class={classes(["group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end`
  }

  if (fn.name === "sheet_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def sheet_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="sheet-overlay"
      class="fixed inset-0 z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"
      style="pointer-events:auto"
    />
    <div
      role="dialog"
      id="radix-id"
      data-state="open"
      data-slot="sheet-content"
      data-side="right"
      tabindex="-1"
      class={classes(["fixed z-50 flex flex-col gap-4 bg-popover bg-clip-padding text-sm text-popover-foreground shadow-lg transition duration-200 ease-in-out data-[side=bottom]:inset-x-0 data-[side=bottom]:bottom-0 data-[side=bottom]:h-auto data-[side=bottom]:border-t data-[side=left]:inset-y-0 data-[side=left]:left-0 data-[side=left]:h-full data-[side=left]:w-3/4 data-[side=left]:border-r data-[side=right]:inset-y-0 data-[side=right]:right-0 data-[side=right]:h-full data-[side=right]:w-3/4 data-[side=right]:border-l data-[side=top]:inset-x-0 data-[side=top]:top-0 data-[side=top]:h-auto data-[side=top]:border-b data-[side=left]:sm:max-w-sm data-[side=right]:sm:max-w-sm data-open:animate-in data-open:fade-in-0 data-[side=bottom]:data-open:slide-in-from-bottom-10 data-[side=left]:data-open:slide-in-from-left-10 data-[side=right]:data-open:slide-in-from-right-10 data-[side=top]:data-open:slide-in-from-top-10 data-closed:animate-out data-closed:fade-out-0 data-[side=bottom]:data-closed:slide-out-to-bottom-10 data-[side=left]:data-closed:slide-out-to-left-10 data-[side=right]:data-closed:slide-out-to-right-10 data-[side=top]:data-closed:slide-out-to-top-10", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
      <button type="button" data-slot="sheet-close" data-variant="ghost" data-size="icon-sm" class="group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium text-sm whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg absolute top-3 right-3">
        <ShadcnLiveview.Components.Icon.icon name="x" />
        <span class="sr-only">Close</span>
      </button>
    </div>
    """
  end`
  }


  if (fn.name === "navigation_menu") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def navigation_menu(assigns) do
    ~H"""
    <nav
      aria-label="Main"
      data-orientation="horizontal"
      dir="ltr"
      data-slot="navigation-menu"
      data-viewport="true"
      class={classes(["group/navigation-menu relative flex max-w-max flex-1 items-center justify-center", @class])}
      {@rest}
    >
      <div style="position:relative">
        {render_slot(@inner_block)}
      </div>
      <div class="absolute top-full left-0 isolate z-50 flex justify-center" />
    </nav>
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

  if (fn.name === "questionnaire") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire(assigns) do
    ~H"""
    <form
      data-slot="questionnaire"
      data-current="0"
      data-total="0"
      novalidate=""
      class={classes(["flex w-full min-w-0 flex-col gap-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </form>
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

  if (fn.name === "accordion") {
    return `  attr :orientation, :string, default: "vertical"
  attr :type, :string, default: "single"
  attr :default_value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion(assigns) do
    ~H"""
    <div
      data-slot="accordion"
      data-orientation={@orientation}
      class={classes(["flex w-full flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "accordion_item") {
    return `  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_item(assigns) do
    ~H"""
    <div
      data-slot="accordion-item"
      data-state="open"
      data-orientation="vertical"
      class={classes(["not-last:border-b", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "accordion_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_content(assigns) do
    ~H"""
    <div
      data-slot="accordion-content"
      data-state="open"
      data-orientation="vertical"
      role="region"
      id="radix-id"
      aria-labelledby="radix-id"
      style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"
      class={classes(["overflow-hidden text-sm data-closed:animate-accordion-up data-open:animate-accordion-down", @class])}
      {@rest}
    >
      <div class="h-(--radix-accordion-content-height) pt-0 pb-2.5 [&_a]:underline [&_a]:underline-offset-3 [&_a]:hover:text-foreground [&_p:not(:last-child)]:mb-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end`
  }

  if (fn.name === "collapsible") {
    return `  attr :open, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def collapsible(assigns) do
    ~H"""
    <div
      data-slot="collapsible"
      data-state={if @open, do: "open", else: "closed"}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }
  if (fn.name === "collapsible_trigger") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def collapsible_trigger(assigns) do
    ~H"""
    <button
      type="button"
      aria-controls="radix-id"
      aria-expanded="true"
      data-state="open"
      data-slot="collapsible-trigger"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end`
  }

  if (fn.name === "collapsible_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def collapsible_content(assigns) do
    ~H"""
    <div
      id="radix-id"
      data-state="open"
      data-slot="collapsible-content"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "tabs") {
    return `  attr :dir, :string, default: "ltr"
  attr :orientation, :string, default: "horizontal"
  attr :default_value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs(assigns) do
    ~H"""
    <div
      dir={@dir}
      data-orientation={@orientation}
      data-slot="tabs"
      phx-hook=".Tabs"
      class={classes(["group/tabs flex gap-2 data-horizontal:flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Tabs">
      export default {
        mounted() {
          this.el.addEventListener("click", (e) => {
            const trigger = e.target.closest("[data-slot=tabs-trigger]");
            if (!trigger) return;
            const val = trigger.getAttribute("data-value") || trigger.getAttribute("value");
            this.el.querySelectorAll("[data-slot=tabs-trigger]").forEach((t) => {
              const match = (t.getAttribute("data-value") || t.getAttribute("value")) === val;
              t.setAttribute("data-state", match ? "active" : "inactive");
              t.setAttribute("aria-selected", match ? "true" : "false");
            });
            this.el.querySelectorAll("[data-slot=tabs-content]").forEach((c) => {
              const match = (c.getAttribute("data-value") || c.getAttribute("value")) === val;
              c.setAttribute("data-state", match ? "active" : "inactive");
              c.hidden = !match;
            });
          });
        }
      }
    </script>
    """
  end`
  }

  if (fn.name === "tabs_list") {
    return `  attr :variant, :string, default: "default"
  attr :orientation, :string, default: "horizontal"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_list(assigns) do
    ~H"""
    <div
      role="tablist"
      aria-orientation={@orientation}
      tabindex="-1"
      data-orientation={@orientation}
      data-slot="tabs-list"
      data-variant={@variant}
      style="outline:none"
      class={classes(["group/tabs-list inline-flex w-fit items-center justify-center rounded-lg p-[3px] text-muted-foreground group-data-horizontal/tabs:h-8 group-data-vertical/tabs:h-fit group-data-vertical/tabs:flex-col data-[variant=line]:rounded-none bg-muted", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "tabs_trigger") {
    return `  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_trigger(assigns) do
    active = (assigns.value == "account")
    assigns = assign(assigns, :active, active)
    ~H"""
    <button
      type="button"
      role="tab"
      aria-selected={to_string(@active)}
      aria-controls="radix-id"
      data-state={if @active, do: "active", else: "inactive"}
      id="radix-id"
      tabindex="-1"
      data-orientation="horizontal"
      data-slot="tabs-trigger"
      class={classes(["relative inline-flex h-[calc(100%-1px)] flex-1 items-center justify-center gap-1.5 rounded-md border border-transparent px-1.5 py-0.5 text-sm font-medium whitespace-nowrap text-foreground/60 transition-all group-data-vertical/tabs:w-full group-data-vertical/tabs:justify-start hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 focus-visible:outline-ring disabled:pointer-events-none disabled:opacity-50 has-data-[icon=inline-end]:pr-1 has-data-[icon=inline-start]:pl-1 dark:text-muted-foreground dark:hover:text-foreground group-data-[variant=default]/tabs-list:data-active:shadow-sm group-data-[variant=line]/tabs-list:data-active:shadow-none [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 group-data-[variant=line]/tabs-list:bg-transparent group-data-[variant=line]/tabs-list:data-active:bg-transparent dark:group-data-[variant=line]/tabs-list:data-active:border-transparent dark:group-data-[variant=line]/tabs-list:data-active:bg-transparent data-active:bg-background data-active:text-foreground dark:data-active:border-input dark:data-active:bg-input/30 dark:data-active:text-foreground after:absolute after:bg-foreground after:opacity-0 after:transition-opacity group-data-horizontal/tabs:after:inset-x-0 group-data-horizontal/tabs:after:bottom-[-5px] group-data-horizontal/tabs:after:h-0.5 group-data-vertical/tabs:after:inset-y-0 group-data-vertical/tabs:after:-right-1 group-data-vertical/tabs:after:w-0.5 group-data-[variant=line]/tabs-list:data-active:after:opacity-100", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end`
  }

  if (fn.name === "tabs_content") {
    return `  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_content(assigns) do
    active = (assigns.value == "account")
    assigns = assign(assigns, :active, active)
    ~H"""
    <div
      data-state={if @active, do: "active", else: "inactive"}
      data-orientation="horizontal"
      role="tabpanel"
      aria-labelledby="radix-id"
      id="radix-id"
      tabindex="0"
      data-slot="tabs-content"
      class={classes(["flex-1 text-sm outline-none", @class])}
      hidden={not @active}
      {if @active, do: %{style: "animation-duration:0s"}, else: %{}}
      {@rest}
    ><%= if @active do %>{render_slot(@inner_block)}<% end %></div>
    """
  end`
  }

  if (fn.name === "drawer_content") {
    return `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="drawer-overlay"
      class="fixed inset-0 z-50 bg-black/10 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"
      style="pointer-events:auto"
    />
    <div
      role="dialog"
      id="radix-id"
      data-state="open"
      data-slot="drawer-content"
      tabindex="-1"
      class={classes(["group/drawer-content fixed z-50 flex h-auto flex-col bg-popover text-sm text-popover-foreground data-[vaul-drawer-direction=bottom]:inset-x-0 data-[vaul-drawer-direction=bottom]:bottom-0 data-[vaul-drawer-direction=bottom]:mt-24 data-[vaul-drawer-direction=bottom]:max-h-[80vh] data-[vaul-drawer-direction=bottom]:rounded-t-xl data-[vaul-drawer-direction=bottom]:border-t data-[vaul-drawer-direction=left]:inset-y-0 data-[vaul-drawer-direction=left]:left-0 data-[vaul-drawer-direction=left]:w-3/4 data-[vaul-drawer-direction=left]:rounded-r-xl data-[vaul-drawer-direction=left]:border-r data-[vaul-drawer-direction=right]:inset-y-0 data-[vaul-drawer-direction=right]:right-0 data-[vaul-drawer-direction=right]:w-3/4 data-[vaul-drawer-direction=right]:rounded-l-xl data-[vaul-drawer-direction=right]:border-l data-[vaul-drawer-direction=top]:inset-x-0 data-[vaul-drawer-direction=top]:top-0 data-[vaul-drawer-direction=top]:mb-24 data-[vaul-drawer-direction=top]:max-h-[80vh] data-[vaul-drawer-direction=top]:rounded-b-xl data-[vaul-drawer-direction=top]:border-b data-[vaul-drawer-direction=left]:sm:max-w-sm data-[vaul-drawer-direction=right]:sm:max-w-sm", @class])}
      {@rest}
    >
      <div class="mx-auto mt-4 hidden h-1 w-[100px] shrink-0 rounded-full bg-muted group-data-[vaul-drawer-direction=bottom]/drawer-content:block" />
      {render_slot(@inner_block)}
    </div>
    """
  end`
  }

  if (fn.name === "slider") {
    return `  attr :default_value, :list, default: [50]
  attr :max, :integer, default: 100
  attr :step, :integer, default: 1
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def slider(assigns) do
    ~H"""
    <span
      dir="ltr"
      data-orientation="horizontal"
      aria-disabled="false"
      data-slot="slider"
      style="--radix-slider-thumb-transform:translateX(-50%)"
      class={classes(["relative flex touch-none items-center select-none data-disabled:opacity-50 data-vertical:h-full data-vertical:min-h-40 data-vertical:w-auto data-vertical:flex-col", @class])}
      {@rest}
    >
      <span
        data-slot="slider-track"
        data-orientation="horizontal"
        class="relative grow overflow-hidden rounded-full bg-muted data-horizontal:h-1 data-horizontal:w-full data-vertical:h-full data-vertical:w-1"
      >
        <span
          data-slot="slider-range"
          data-orientation="horizontal"
          style="left:0%;right:50%"
          class="absolute bg-primary select-none data-horizontal:h-full data-vertical:w-full"
        />
      </span>
      <span style="transform:var(--radix-slider-thumb-transform);position:absolute;left:calc(0% + 0px)">
        <span
          role="slider"
          aria-valuemin="0"
          aria-valuemax="100"
          aria-orientation="horizontal"
          data-orientation="horizontal"
          tabindex="0"
          data-slot="slider-thumb"
          class="relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50"
          style="display:none"
          data-radix-collection-item=""
        />
      </span>
      <input style="display:none" />
    </span>
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

  attrsLines.push(`  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)`)
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

    const cases: string[] = []
    for (const [k1, c1] of Object.entries(map1)) {
      for (const [k2, c2] of Object.entries(map2)) {
        const merged = cn(fn.baseClasses, c1, c2)
        cases.push(`      {"${k1}", "${k2}"} -> "${merged.replace(/"/g, '\\"')}"`)
      }
    }
    const defMerged = cn(fn.baseClasses, map1[def1] || "", map2[def2] || "")
    cases.push(`      _ -> "${defMerged.replace(/"/g, '\\"')}"`)

    variantHelpers.push(`  defp ${fn.name}_classes(${var1}, ${var2}) do\n    case {to_string(${var1} || "${def1}"), to_string(${var2} || "${def2}")} do\n${cases.join("\n")}\n    end\n  end`)
  } else if (variantEntries.length === 1) {
    const [var1, map1] = variantEntries[0]
    const def1 = fn.defaultVariants?.[var1] ?? Object.keys(map1)[0] ?? "default"

    classExpr = `[${fn.name}_classes(@${var1}), @class]`

    const cases: string[] = []
    for (const [k1, c1] of Object.entries(map1)) {
      const merged = cn(fn.baseClasses, c1)
      cases.push(`      "${k1}" -> "${merged.replace(/"/g, '\\"')}"`)
    }
    const defMerged = cn(fn.baseClasses, map1[def1] || "")
    cases.push(`      _ -> "${defMerged.replace(/"/g, '\\"')}"`)

    variantHelpers.push(`  defp ${fn.name}_classes(${var1}) do\n    case to_string(${var1} || "${def1}") do\n${cases.join("\n")}\n    end\n  end`)
  } else {
    classExpr = `[${classExpr}, @class]`
  }
  classExpr = `classes(${classExpr})`

  let hookTag = ""
  let hookAttr = ""
  if (hook && isPrimary) {
    hookAttr = ` phx-hook=".${hook.name}"`
    hookTag = `
    <script :type={Phoenix.LiveView.ColocatedHook} name=".${hook.name}">
      ${hook.js.trim()}
    </script>`
  }

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

  const template = isVoid
    ? `  def ${fn.name}(assigns) do
    ~H"""
    <${fn.tag}
      data-slot="${fn.slotName}"${dataVariantAttrs}${hookAttr}
      class={${classExpr}}
      {@rest}
    />${hookTag}
    """
  end`
    : `  def ${fn.name}(assigns) do
    ~H"""
    <${fn.tag}
      data-slot="${fn.slotName}"${dataVariantAttrs}${hookAttr}
      class={${classExpr}}
      {@rest}
    >${fn.extraInnerMarkup ?? ""}
      {render_slot(@inner_block)}
    </${fn.tag}>${hookTag}
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

    function walkJsx(n: ts.Node) {
      if (ts.isJsxElement(n) || ts.isJsxSelfClosingElement(n)) {
        const opening = ts.isJsxElement(n) ? n.openingElement : n
        const rawTag = opening.tagName.getText(sf)

        for (const prop of opening.attributes.properties) {
          if (ts.isJsxAttribute(prop) && prop.name) {
            const attrName = prop.name.text
            if (attrName === "data-slot" && prop.initializer && ts.isStringLiteral(prop.initializer)) {
              foundSlot = prop.initializer.text
              foundTag = rawTag
            }
            if (attrName === "data-variant") {
              hasDataVariant = true
            }
            if (attrName === "data-size") {
              hasDataSize = true
            }
            if (attrName === "role" && prop.initializer && ts.isStringLiteral(prop.initializer)) {
              staticAttrsList.push(`role="${prop.initializer.text}"`)
            }
            if (attrName === "className" && prop.initializer) {
              if (ts.isJsxExpression(prop.initializer) && prop.initializer.expression) {
                const expr = prop.initializer.expression
                if (ts.isCallExpression(expr)) {
                  const arg0 = expr.arguments[0]
                  if (arg0 && (ts.isStringLiteral(arg0) || ts.isNoSubstitutionTemplateLiteral(arg0))) {
                    foundClasses = expr.arguments
                      .filter((arg): arg is ts.StringLiteral | ts.NoSubstitutionTemplateLiteral =>
                        ts.isStringLiteral(arg) || ts.isNoSubstitutionTemplateLiteral(arg))
                      .map((arg) => arg.text)
                      .join(" ").replace(/\s+/g, " ").trim()
                  }
                } else if (ts.isStringLiteral(expr) || ts.isNoSubstitutionTemplateLiteral(expr)) {
                  foundClasses = expr.text.replace(/\s+/g, " ").trim()
                }
              } else if (ts.isStringLiteral(prop.initializer) || ts.isNoSubstitutionTemplateLiteral(prop.initializer)) {
                foundClasses = prop.initializer.text.replace(/\s+/g, " ").trim()
              }
            }
          }
        }
      }
      ts.forEachChild(n, walkJsx)
    }
    walkJsx(node)

    let finalTag = resolveHtmlTag(name, foundTag)

    const specialAttrs: { name: string; type: string; default?: string }[] = []
    if (fnSnakeName === "attachment") {
      specialAttrs.push({ name: "state", type: "string", default: '"done"' })
      staticAttrsList.push('data-state={@state} data-orientation={@orientation}')
    }
    if (fnSnakeName === "input_group_addon") {
      staticAttrsList.push('data-align={@align}')
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
    const radixTextComponents: Record<string, true> = {
      dialog_title: true,
      alert_dialog_title: true,
      sheet_title: true,
      drawer_title: true,
      dialog_description: true,
      alert_dialog_description: true,
      sheet_description: true,
      drawer_description: true,
    }
    if (radixTextComponents[fnSnakeName]) {
      staticAttrsList.push('id="radix-id"')
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

  const hook = getInteractiveHook(fileName)

  return {
    name: fileName,
    moduleName,
    functions,
    hook,
  }
}


function getInteractiveHook(name: string): { name: string; js: string } | undefined {
  switch (name) {
    case "accordion":
      return {
        name: "Accordion",
        js: `export default {
          mounted() {
            this.el.addEventListener("click", (e) => {
              const trigger = e.target.closest("[data-slot=accordion-trigger]");
              if (!trigger) return;
              const item = trigger.closest("[data-slot=accordion-item]");
              if (!item) return;
              const isOpen = item.getAttribute("data-state") === "open";
              item.setAttribute("data-state", isOpen ? "closed" : "open");
              trigger.setAttribute("aria-expanded", isOpen ? "false" : "true");
              trigger.setAttribute("data-state", isOpen ? "closed" : "open");
              const content = item.querySelector("[data-slot=accordion-content]");
              if (content) {
                content.setAttribute("data-state", isOpen ? "closed" : "open");
                content.hidden = isOpen;
              }
            });
          }
        }`,
      }
    case "tabs":
      return {
        name: "Tabs",
        js: `export default {
          mounted() {
            this.el.addEventListener("click", (e) => {
              const trigger = e.target.closest("[data-slot=tabs-trigger]");
              if (!trigger) return;
              const val = trigger.getAttribute("data-value") || trigger.getAttribute("value");
              this.el.querySelectorAll("[data-slot=tabs-trigger]").forEach((t) => {
                const match = (t.getAttribute("data-value") || t.getAttribute("value")) === val;
                t.setAttribute("data-state", match ? "active" : "inactive");
                t.setAttribute("aria-selected", match ? "true" : "false");
              });
              this.el.querySelectorAll("[data-slot=tabs-content]").forEach((c) => {
                const match = (c.getAttribute("data-value") || c.getAttribute("value")) === val;
                c.setAttribute("data-state", match ? "active" : "inactive");
                c.hidden = !match;
              });
            });
          }
        }`,
      }
    case "dialog":
    case "alert-dialog":
    case "sheet":
      return {
        name: toPascalCase(name),
        js: `export default {
          mounted() {
            this.el.addEventListener("click", (e) => {
              if (e.target.closest("[data-slot$=-close]") || e.target.closest("[data-slot$=-cancel]")) {
                this.el.style.display = "none";
              }
            });
            window.addEventListener("keydown", (e) => {
              if (e.key === "Escape" && this.el.style.display !== "none") {
                this.el.style.display = "none";
              }
            });
          }
        }`,
      }
    case "dropdown-menu":
    case "popover":
      return {
        name: toPascalCase(name),
        js: `export default {
          mounted() {
            const trigger = this.el.querySelector("[data-slot$=-trigger]");
            const content = this.el.querySelector("[data-slot$=-content]");
            if (trigger && content) {
              trigger.addEventListener("click", () => {
                const isOpen = content.getAttribute("data-state") === "open";
                content.setAttribute("data-state", isOpen ? "closed" : "open");
                content.style.display = isOpen ? "none" : "";
              });
            }
          }
        }`,
      }
    case "switch":
      return {
        name: "Switch",
        js: `export default {
          mounted() {
            this.el.addEventListener("click", () => {
              const checked = this.el.getAttribute("data-state") === "checked";
              this.el.setAttribute("data-state", checked ? "unchecked" : "checked");
              this.el.setAttribute("aria-checked", checked ? "false" : "true");
            });
          }
        }`,
      }
    case "collapsible":
      return {
        name: "Collapsible",
        js: `export default {
          mounted() {
            const trigger = this.el.querySelector("[data-slot=collapsible-trigger]");
            const content = this.el.querySelector("[data-slot=collapsible-content]");
            if (trigger && content) {
              trigger.addEventListener("click", () => {
                const isOpen = this.el.getAttribute("data-state") === "open";
                this.el.setAttribute("data-state", isOpen ? "closed" : "open");
                content.hidden = isOpen;
              });
            }
          }
        }`,
      }
    default:
      return undefined
  }
}

export async function generateAllComponents(): Promise<void> {
  const outDir = path.resolve("lib/shadcn_liveview/components")
  await fs.mkdir(outDir, { recursive: true })

  const files = (await fs.readdir("vendor/shadcn/ui")).filter((f) => f.endsWith(".tsx")).sort()
  console.log(`Found ${files.length} vendored UI component files.`)

  const moduleNames: string[] = []
  const controlClasses = new Map<string, string>()
  for (const control of ["input", "textarea"]) {
    const source = await fs.readFile(path.join("vendor/shadcn/ui", control + ".tsx"), "utf8")
    const controlSpec = parseComponentAST(control, source)
    controlClasses.set("input_group_" + control, controlSpec.functions.find((fn) => fn.name === control)!.baseClasses)
  }

  for (const f of files) {
    const compName = f.replace(/\.tsx$/, "")
    const code = await fs.readFile(path.join("vendor/shadcn/ui", f), "utf8")
    const spec = parseComponentAST(compName, code)
    // InputGroup controls compose the upstream Input/Textarea styles before overrides.
    for (const fn of spec.functions) {
      const inherited = controlClasses.get(fn.name)
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

  const namesList = fixtures.map((f) => `"${f.name}"`).join(", ")
  const galleryCode = `defmodule ShadcnLiveview.Gallery do
  @moduledoc false
  use Phoenix.Component
  use ShadcnLiveview

  def names, do: [${namesList}]

  def render_html(name) do
    case render_fixture(name) do
      nil -> nil
      rendered -> Phoenix.HTML.Safe.to_iodata(rendered) |> IO.iodata_to_binary()
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
