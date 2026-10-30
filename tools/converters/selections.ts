import type { ComponentSpec } from "../generate"
import { cn } from "cn"
import { toggleVariants } from "../../vendor/shadcn/ui/toggle"
import { selectionHook, menubarHook } from "./selections-hooks"

const radioClasses = "group/radio-group-item peer relative flex aspect-square size-4 shrink-0 rounded-full border border-input outline-none group-has-[:focus-visible]/field-label:ring-0 group-has-[:focus-visible]/field-label:not-data-checked:border-input after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 aria-invalid:aria-checked:border-primary dark:bg-input/30 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:border-primary data-checked:bg-primary data-checked:text-primary-foreground group-has-[:focus-visible]/field-label:data-checked:border-primary dark:data-checked:bg-primary"


function radio(spec: ComponentSpec): string {
  return String.raw`defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Native-form-compatible radio groups with explicit slot contexts.

  The root yields its context through :let; pass it to each radio_group_item.
  IDs belong to the caller. value enables server control and on_value_change
  names a LiveView event receiving %{id, value}. Without value, default_value
  initializes local selection. field={@form[:plan]} infers id, name and a
  controlled value (nothing selected when nil) and composes with form_field.
  Selections update immediately and dispatch native input and change events in
  both modes, so phx-change sees them; server values win on the next patch.
  Arrow keys select, Space checks, and form reset restores the initial value.
  SSR focus stops are activated by the colocated hook.
  Hook events honor phx-target on the root or nearest containing element.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :orientation, :string, default: nil, values: [nil, "horizontal", "vertical"]
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :loop, :boolean, default: true
  attr :on_value_change, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Yields the radio selection and native form context to its item slot."
  def radio_group(assigns) do
    assigns = ShadcnLiveview.Form.bind(assigns, :radio_group)
    if is_nil(assigns.id), do: raise(ArgumentError, "radio_group requires an id or form field")
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value
    assigns = assign(assigns, context: %{value: value, name: assigns.name, form: assigns.form, required: assigns.required, disabled: assigns.disabled, orientation: assigns.orientation, invalid: assigns.rest[:"aria-invalid"]}, values: if(is_nil(value), do: [], else: [value]))
    ~H"""
    <div id={@id} role="radiogroup" aria-required={to_string(@required)} aria-orientation={@orientation} data-disabled={if @disabled, do: ""} dir={@dir} data-slot="radio-group" tabindex="-1" data-orientation={@orientation} style="outline:none" class={classes(["grid w-full gap-2", @class])} phx-hook=".RadioGroup" phx-values={Jason.encode!(@values)} phx-controlled={to_string(not is_nil(@value))} phx-orientation={@orientation} phx-loop={to_string(@loop)} phx-roving="true" phx-form={@form} phx-change-event={@on_value_change} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".RadioGroup">${selectionHook}</script>
    """
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(aria-invalid)

  @doc "Renders a radio button and its real, successful native radio input."
  def radio_group_item(assigns) do
    assigns = assign(assigns, checked: assigns.context.value == assigns.value, disabled: assigns.disabled or assigns.context.disabled, rest: Map.put_new(assigns.rest, :"aria-invalid", assigns.context[:invalid]))
    ~H"""
    <button id={@id} type="button" role="radio" aria-checked={to_string(@checked)} data-state={if @checked, do: "checked", else: "unchecked"} data-disabled={if @disabled, do: ""} disabled={@disabled} value={@value} data-slot="radio-group-item" tabindex="-1" data-orientation={@context.orientation} class={classes(["${radioClasses}", @class])} {@rest}>
      <.indicator :if={@checked} disabled={@disabled} />
    </button>
    <input type="radio" aria-hidden="true" tabindex="-1" name={@context.name} form={@context.form} value={@value} checked={@checked} required={@context.required} disabled={@disabled} style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)" />
    """
  end

  attr :disabled, :boolean, default: false
  defp indicator(assigns) do
    ~H"""
    <span data-state="checked" data-disabled={if @disabled, do: ""} data-slot="radio-group-indicator" class="flex size-4 items-center justify-center"><span class="absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary-foreground"></span></span>
    """
  end

end
`
}

function toggle(spec: ComponentSpec): string {
  const itemBase = spec.functions.find(f => f.name === "toggle_group_item")!.baseClasses
  const variants = ["default", "outline"] as const
  const sizes = ["default", "sm", "lg"] as const
  const clauses = variants.flatMap(variant => sizes.map(size => `  defp item_classes("${variant}", "${size}"), do: ${JSON.stringify(cn(itemBase, toggleVariants({ variant, size })))}`)).join("\n")
  return String.raw`defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Single- and multiple-selection toggle buttons with explicit :let contexts.

  Pass the root context to each item. Root variant, size, spacing and disabled
  state propagate without hidden render state. value enables server control;
  on_value_change names a LiveView event receiving %{id, value}. Single values
  are strings (empty when deselected); multiple values are lists. Native buttons
  retain Space/Enter activation while the hook provides directional roving focus.
  Hook events honor phx-target on the root or nearest containing element.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string, required: true
  attr :type, :string, required: true, values: ["single", "multiple"]
  attr :value, :any, default: nil
  attr :default_value, :any, default: nil
  attr :variant, :string, default: nil, values: [nil, "default", "outline"]
  attr :size, :string, default: nil, values: [nil, "default", "sm", "lg"]
  attr :spacing, :integer, default: 2
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :disabled, :boolean, default: false
  attr :roving_focus, :boolean, default: true
  attr :loop, :boolean, default: true
  attr :on_value_change, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a radiogroup or toolbar and yields its item context."
  def toggle_group(assigns) do
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value
    values = if assigns.type == "multiple", do: value || [], else: if(value in [nil, ""], do: [], else: [value])
    assigns = assign(assigns, values: values, context: %{values: values, type: assigns.type, disabled: assigns.disabled, variant: assigns.variant, size: assigns.size, spacing: assigns.spacing, roving_focus: assigns.roving_focus})
    ~H"""
    <div id={@id} dir={@dir} role={if @type == "single", do: "radiogroup", else: "toolbar"} data-slot="toggle-group" data-variant={@variant} data-size={@size} data-spacing={@spacing} data-orientation={@orientation} style={if @roving_focus, do: "outline:none;--gap:#{@spacing}", else: "--gap:#{@spacing}"} tabindex={if @roving_focus, do: "-1"} class={classes(["${spec.functions.find(f => f.name === "toggle_group")!.baseClasses}", @class])} phx-hook=".ToggleGroup" phx-values={Jason.encode!(@values)} phx-controlled={to_string(not is_nil(@value))} phx-selection-type={@type} phx-orientation={@orientation} phx-loop={to_string(@loop)} phx-roving={to_string(@roving_focus)} phx-change-event={@on_value_change} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ToggleGroup">${selectionHook}</script>
    """
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :variant, :string, default: "default", values: ["default", "outline"]
  attr :size, :string, default: "default", values: ["default", "sm", "lg"]
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a selected or unselected native toggle button within its context."
  def toggle_group_item(assigns) do
    assigns = assign(assigns, pressed: assigns.value in assigns.context.values, disabled: assigns.disabled or assigns.context.disabled, variant: assigns.context.variant || assigns.variant, size: assigns.context.size || assigns.size)
    ~H"""
    <button id={@id} type="button" data-state={if @pressed, do: "on", else: "off"} data-disabled={if @disabled, do: ""} disabled={@disabled} role={if @context.type == "single", do: "radio"} aria-checked={if @context.type == "single", do: to_string(@pressed)} aria-pressed={if @context.type == "multiple", do: to_string(@pressed)} data-slot="toggle-group-item" data-variant={@variant} data-size={@size} data-spacing={@context.spacing} tabindex={if @context.roving_focus, do: "-1"} class={classes([item_classes(@variant, @size), @class])} phx-value={@value} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

${clauses}
end
`
}


function menubar(spec: ComponentSpec): string {
  const classes = Object.fromEntries(spec.functions.map(f => [f.name, f.baseClasses]))
  classes.menubar_checkbox_item = "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-1.5 pl-7 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none [&_svg]:pointer-events-none [&_svg]:shrink-0"
  classes.menubar_radio_item = "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-1.5 pl-7 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
  classes.menubar_sub_trigger = "flex cursor-default items-center gap-1.5 rounded-md px-1.5 py-1 text-sm outline-none select-none focus:bg-accent focus:text-accent-foreground data-inset:pl-7 data-open:bg-accent data-open:text-accent-foreground [&_svg:not([class*='size-'])]:size-4"
  const simple = [
    ["menubar_group", "div", 'role="group"'],
    ["menubar_label", "div", "data-inset={@inset}"],
    ["menubar_separator", "div", 'role="separator" aria-orientation="horizontal"'],
    ["menubar_shortcut", "span", ""],
  ].map(([name, tag, attrs]) => String.raw`
  attr :class, :any, default: nil
  ${name === "menubar_label" ? "attr :inset, :boolean, default: nil" : ""}
  attr :rest, :global
  slot :inner_block
  def ${name}(assigns) do
    ~H"""
    <${tag} data-slot="${name.replaceAll("_", "-")}" ${attrs} class={classes(["${classes[name]}", @class])} {@rest}>{render_slot(@inner_block)}</${tag}>
    """
  end
`).join("\n")
  return String.raw`defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  An accessible menubar with explicit, instance-local slot contexts.

  Pass the root's :let context to each menu, then the menu's trigger/content
  slot context to its primitives. LiveView owns portal mounting: handle
  on_value_change by assigning value from the %{id, value} event payload.
  default_value only supplies initial selection. The hook positions mounted
  content, implements keyboard focus and requests state changes without HTML
  serialization. Submenus similarly use open and on_open_change.
  All selection, dismissal and submenu events honor phx-target on the root
  or nearest containing element.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  import ShadcnLiveview.Components.Icon, only: [icon: 1]

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: ""
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :loop, :boolean, default: true
  attr :on_value_change, :string, default: "shadcn:menubar-change"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a horizontal menu bar and yields its selection context."
  def menubar(assigns) do
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value
    assigns = assign(assigns, selected: value, context: %{value: value, dir: assigns.dir})
    ~H"""
    <div id={@id} role="menubar" data-slot="menubar" tabindex="-1" data-orientation="horizontal" style="outline:none" class={classes(["${classes.menubar}", @class])} phx-hook=".Menubar" phx-value={@selected} phx-dir={@dir} phx-change-event={@on_value_change} phx-loop={to_string(@loop)} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Menubar">${menubarHook}</script>
    """
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :trigger_id, :string, default: nil
  attr :content_id, :string, default: nil
  slot :trigger, required: true
  slot :content, required: true

  @doc "Connects trigger and portal content through a stable caller-owned menu ID."
  def menubar_menu(assigns) do
    context = %{value: assigns.value, open: assigns.context.value == assigns.value, dir: assigns.context.dir, trigger_id: assigns.trigger_id || "radix-#{assigns.id}-trigger", content_id: assigns.content_id || "radix-#{assigns.id}-content"}
    assigns = assign(assigns, :context, context)
    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @context.open do %>{render_slot(@content, @context)}<% end %>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_trigger(assigns) do
    ~H"""
    <button id={@id || @context.trigger_id} type="button" role="menuitem" aria-haspopup="menu" aria-expanded={to_string(@context.open)} aria-controls={if @context.open, do: @context.content_id} data-state={if @context.open, do: "open", else: "closed"} data-disabled={if @disabled, do: ""} disabled={@disabled} data-slot="menubar-trigger" tabindex="-1" data-orientation="horizontal" class={classes(["${classes.menubar_trigger}", @class])} phx-menu-value={@context.value} phx-content-id={@context.content_id} {@rest}>{render_slot(@inner_block)}</button>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :align, :string, default: "start", values: ["start", "center", "end"]
  attr :side, :string, default: "bottom", values: ["top", "right", "bottom", "left"]
  attr :side_offset, :integer, default: 8
  attr :align_offset, :integer, default: -4
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_content(assigns) do
    ~H"""
    <div data-radix-popper-content-wrapper="" style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:" dir={@context.dir}>
      <div id={@id || @context.content_id} data-side={@side} data-align={@align} role="menu" aria-orientation="vertical" data-state="open" data-radix-menu-content="" dir={@context.dir} aria-labelledby={@context.trigger_id} data-radix-menubar-content="" data-slot="menubar-content" class={classes(["${classes.menubar_content}", @class])} style="outline:none;--radix-menubar-content-transform-origin:var(--radix-popper-transform-origin);--radix-menubar-content-available-width:var(--radix-popper-available-width);--radix-menubar-content-available-height:var(--radix-popper-available-height);--radix-menubar-trigger-width:var(--radix-popper-anchor-width);--radix-menubar-trigger-height:var(--radix-popper-anchor-height);animation:none" tabindex="-1" data-orientation="vertical" phx-side={@side} phx-side-offset={@side_offset} phx-align-offset={@align_offset} {@rest}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :variant, :string, default: "default", values: ["default", "destructive"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_item(assigns) do
    ~H"""
    <div role="menuitem" data-slot="menubar-item" data-inset={inset_value(@inset)} data-variant={@variant} aria-disabled={if @disabled, do: "true"} data-disabled={if @disabled, do: ""} tabindex="-1" data-orientation="vertical" class={classes(["${classes.menubar_item}", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """

  end
  defp inset_value(nil), do: nil
  defp inset_value(value), do: to_string(value)

  attr :id, :string, required: true
  attr :checked, :any, default: false
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :on_checked_change, :string, default: "shadcn:menu-check-change"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_checkbox_item(assigns) do
    assigns = assign(assigns, state: if(assigns.checked == "indeterminate", do: "indeterminate", else: if(assigns.checked, do: "checked", else: "unchecked")))
    ~H"""
    <div id={@id} role="menuitemcheckbox" aria-checked={if @checked == "indeterminate", do: "mixed", else: to_string(@checked)} data-state={@state} aria-disabled={if @disabled, do: "true"} data-disabled={if @disabled, do: ""} data-slot="menubar-checkbox-item" data-inset={inset_value(@inset)} tabindex="-1" data-orientation="vertical" class={classes(["${classes.menubar_checkbox_item}", @class])} phx-change-event={@on_checked_change} {@rest}>
      <span class="pointer-events-none absolute left-1.5 flex size-4 items-center justify-center [&_svg:not([class*='size-'])]:size-4"><span :if={@checked} data-state={@state}><.icon name="check" /></span></span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :on_value_change, :string, default: "shadcn:menu-radio-change"
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_radio_group(assigns) do
    ~H"""
    <div id={@id} role="group" data-slot="menubar-radio-group" phx-change-event={@on_value_change} {@rest}>{render_slot(@inner_block, %{value: @value})}</div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_radio_item(assigns) do
    assigns = assign(assigns, checked: assigns.context.value == assigns.value)
    ~H"""
    <div id={@id} role="menuitemradio" aria-checked={to_string(@checked)} data-state={if @checked, do: "checked", else: "unchecked"} aria-disabled={if @disabled, do: "true"} data-disabled={if @disabled, do: ""} data-slot="menubar-radio-item" data-inset={inset_value(@inset)} tabindex="-1" data-orientation="vertical" class={classes(["${classes.menubar_radio_item}", @class])} phx-value={@value} {@rest}>
      <span class="pointer-events-none absolute left-1.5 flex size-4 items-center justify-center [&_svg:not([class*='size-'])]:size-4"><span :if={@checked} data-state="checked"><.icon name="check" /></span></span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :open, :boolean, default: false
  attr :on_open_change, :string, default: "shadcn:menubar-sub-change"
  slot :trigger, required: true
  slot :content, required: true
  def menubar_sub(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, open: assigns.open, on_open_change: assigns.on_open_change, trigger_id: "radix-#{assigns.id}-trigger", content_id: "radix-#{assigns.id}-content", dir: assigns.dir})
    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @open do %>{render_slot(@content, @context)}<% end %>
    """
  end

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_sub_trigger(assigns) do
    ~H"""
    <div id={@context.trigger_id} role="menuitem" aria-haspopup="menu" aria-expanded={to_string(@context.open)} aria-controls={if @context.open, do: @context.content_id} data-state={if @context.open, do: "open", else: "closed"} aria-disabled={if @disabled, do: "true"} data-disabled={if @disabled, do: ""} data-radix-menubar-subtrigger="" data-slot="menubar-sub-trigger" data-inset={inset_value(@inset)} tabindex="-1" data-orientation="vertical" class={classes(["${classes.menubar_sub_trigger}", @class])} phx-content-id={@context.content_id} phx-sub-id={@context.id} phx-change-event={@context.on_open_change} {@rest}>{render_slot(@inner_block)}<.icon name="chevron-right" class="cn-rtl-flip ml-auto size-4" /></div>
    """
  end

  attr :context, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def menubar_sub_content(assigns) do
    ~H"""
    <div data-radix-popper-content-wrapper="" style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:" dir={@context.dir}>
      <div id={@context.content_id} role="menu" aria-orientation="vertical" aria-labelledby={@context.trigger_id} data-side={if @context.dir == "rtl", do: "left", else: "right"} data-align="start" data-state="open" data-radix-menu-content="" data-radix-menubar-content="" dir={@context.dir} data-slot="menubar-sub-content" tabindex="-1" data-orientation="vertical" style="outline:none;--radix-menubar-content-transform-origin:var(--radix-popper-transform-origin);--radix-menubar-content-available-width:var(--radix-popper-available-width);--radix-menubar-content-available-height:var(--radix-popper-available-height);--radix-menubar-trigger-width:var(--radix-popper-anchor-width);--radix-menubar-trigger-height:var(--radix-popper-anchor-height);animation:none" class={classes(["${classes.menubar_sub_content}", @class])} {@rest}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  slot :inner_block
  def menubar_portal(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

${simple}

end
`
}

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name === "radio-group") return radio(spec)
  if (spec.name === "toggle-group") return toggle(spec)
  if (spec.name === "menubar") return menubar(spec)
  return undefined
}
