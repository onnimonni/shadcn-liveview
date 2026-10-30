// Structural differences between React shadcn/ui and shadcn_liveview, per component family.
// test/template-to-liveview.test.ts checks every function/attr named here against the
// component metadata, so a library API change fails the tool tests instead of producing
// uncompilable output.

/** Roots that yield a context with `:let`; children receive it through `context`/named attrs. */
export const yieldingRoots: Record<string, { key: string; variable: string }> = {
  sidebar_provider: { key: "sidebar", variable: "sidebar" },
  tabs: { key: "tabs", variable: "tabs" },
  accordion: { key: "accordion", variable: "accordion" },
  accordion_item: { key: "accordion_item", variable: "item" },
  collapsible: { key: "collapsible", variable: "collapsible" },
  toggle_group: { key: "toggle_group", variable: "group" },
  radio_group: { key: "radio_group", variable: "group" },
  carousel: { key: "carousel", variable: "carousel" },
  navigation_menu: { key: "navigation_menu", variable: "nav" },
  menubar: { key: "menubar", variable: "menubar" },
  input_otp: { key: "input_otp", variable: "otp" },
  resizable_panel_group: { key: "resizable", variable: "group" },
  message_scroller_provider: { key: "message_scroller", variable: "scroller" },
}

/** Context key that satisfies a required map attr (`context`, `sidebar`, ...) of a function. */
export function contextKey(fnName: string, family: string, attr: string): string {
  if (attr === "context") {
    if (fnName === "accordion_trigger" || fnName === "accordion_content") return "accordion_item"
    if (family === "resizable") return "resizable"
    return family
  }
  if (attr === "group") return "resizable"
  return attr
}

/** Families rendered through `<:trigger :let>`/`<:content :let>` slots with `{popup.trigger}`. */
export const popupFamilies: Record<string, { trigger: "spread" | "component"; contentFn: string }> = {
  dropdown_menu: { trigger: "spread", contentFn: "dropdown_menu_content" },
  popover: { trigger: "spread", contentFn: "popover_content" },
  tooltip: { trigger: "spread", contentFn: "tooltip_content" },
  hover_card: { trigger: "spread", contentFn: "hover_card_content" },
  context_menu: { trigger: "component", contentFn: "context_menu_content" },
}

/** Families rendered as `<.dialog>` with `<:trigger :let={modal}>` / `<:content :let={modal}>`. */
export const modalFamilies: Record<string, true> = { dialog: true, alert_dialog: true, sheet: true, drawer: true }

/** React-only wrappers rendered as their children. */
export const transparentComponents: Record<string, true> = {
  DropdownMenuPortal: true,
  DialogPortal: true,
  SheetPortal: true,
  DrawerPortal: true,
  AlertDialogPortal: true,
  PopoverPortal: true,
  TooltipPortal: true,
  SelectPortal: true,
  ContextMenuPortal: true,
  HoverCardPortal: true,
}

/** usage-rules sections an agent must follow to finish each kind of TODO. */
export const rules = {
  state: "usage-rules.md#state-model-applies-to-every-interactive-family",
  mapping: "usage-rules.md#react-shadcn--shadcn_liveview",
  icons: "usage-rules.md#navigation-icons-and-styling",
  modal: "usage-rules/overlays.md#dialog--alert-dialog--sheet--drawer",
  popup: "usage-rules/overlays.md#dropdown--context-menu--popover--select--tooltip",
  sidebar: "usage-rules/overlays.md#sidebar",
  toast: "usage-rules/overlays.md#toasts",
  forms: "usage-rules/forms.md",
  tables: "usage-rules/data-tables.md",
  components: "usage-rules/components.md",
}

export function familyRule(family: string): string {
  if (modalFamilies[family]) return rules.modal
  if (popupFamilies[family] || family === "select") return rules.popup
  if (family === "sidebar") return rules.sidebar
  if (family === "sonner") return rules.toast
  if (family === "form" || family === "field") return rules.forms
  if (family === "table" || family === "pagination" || family === "data_table") return rules.tables
  return `${rules.components} (\`${family}\` row)`
}

/** Library controls that bind to a form field with `field={@form[:name]}`. */
export const fieldControls: Record<string, true> = {
  input: true,
  textarea: true,
  checkbox: true,
  switch: true,
  native_select: true,
  radio_group: true,
}

/**
 * Functions whose name the installer's CoreComponents shadows with a different API
 * (`use ShadcnLiveview, except: [...]`). They are called module-qualified so the output
 * compiles both with and without the installer. `button` and `icon` wrappers are compatible.
 */
export const qualifiedFunctions: Record<string, string> = { input: "Input", table: "Table" }

/** Supported React event props per family-agnostic element and the phx binding they become. */
export const clickEvents: Record<string, true> = { onClick: true, onSelect: true }
