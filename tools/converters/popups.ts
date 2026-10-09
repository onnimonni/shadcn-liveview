import type { ComponentSpec } from "../generate"
import { hook } from "./popups-hook"

const families: Record<string, true> = {"context-menu": true, "dropdown-menu": true, "hover-card": true, popover: true, select: true, tooltip: true}


export function generateComponent(spec: ComponentSpec): string | undefined {
  if (!families[spec.name]) return undefined
  const family = spec.name
  const root = family.replaceAll("-", "_")
  const cls = (name: string) => JSON.stringify(spec.functions.find(fn => fn.name === name)?.baseClasses || "")
  const isMenu = family === "dropdown-menu" || family === "context-menu"
  const tooltip = family === "tooltip"
  const select = family === "select"
  const hover = family === "hover-card"
  const contentClass = cls(`${root}_content`)
  const state = tooltip ? 'if(assigns.open, do: "instant-open", else: "closed")' : 'if(assigns.open, do: "open", else: "closed")'
  let source = `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Accessible ${family} with explicit caller identity and slot-scoped context.

  Supply an \`:id\` and a named \`:trigger\` slot receiving a context map.
  Spread \`context.trigger\` on exactly one native trigger${select || family === "context-menu" ? ', or pass the context map to the family trigger component' : ''}.
  ${select ? 'Declare options with stable IDs, values, labels, and rendered option slots; optional group slots label option groups.' : 'The named content slot receives the same context; pass it to the content component.'}
  The LiveView owns open and selection state and renders content only when open.
  The colocated hook requests transitions, positions server-rendered content,
  and handles dismissal, focus, keyboard navigation, and ${select ? 'native form synchronization' : 'pointer interactions'}.
  Handle \`:on_change\` (default \`shadcn:popup-change\`) with \`id\`, \`action\`,
  and \`value\` and update the corresponding root assigns.
  Set phx-target on this wrapperless root (or its optional \`:target\`) to route
  every hook event to a LiveComponent. The slot context forwards the target to
  its native trigger; the trigger also inherits its nearest containing phx-target.
  ${isMenu ? 'Menu selections include `role` and `checked`; checkbox changes update their own value key, while radio selections update the group value.' : 'Escape dismisses the owning popup and restores focus to its trigger.'}
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  ${select || isMenu ? 'alias ShadcnLiveview.Components.Icon' : ''}

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :dir, :string, default: "ltr", values: ~w(ltr rtl)
  attr :side, :string, default: "${tooltip ? "top" : "bottom"}", values: ~w(top right bottom left)
  attr :align, :string, default: "${isMenu ? "start" : "center"}", values: ~w(start center end)
  attr :side_offset, :integer, default: ${tooltip ? 0 : 4}
  attr :open_delay, :integer, default: ${hover ? 700 : 0}
  attr :close_delay, :integer, default: ${hover ? 300 : 100}
  attr :on_change, :string, default: "shadcn:popup-change"
  attr :target, :any, default: nil
  attr :rest, :global
  ${select ? `attr :value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :required, :boolean, default: false
  attr :placeholder, :string, default: ""
  attr :position, :string, default: "item-aligned", values: ~w(item-aligned popper)
  slot :option, required: true do
    attr :id, :string, required: true
    attr :value, :string, required: true
    attr :label, :string, required: true
    attr :disabled, :boolean
    attr :class, :string
    attr :group, :string
  end
  slot :group do
    attr :id, :string, required: true
    attr :label, :string, required: true
  end` : ''}
  slot :trigger, required: true
  ${select ? '' : 'slot :content, required: true'}

  @doc "Renders a ${family} root without a synthetic DOM wrapper."
  def ${root}(assigns) do
    context = %{id: assigns.id, target: assigns.target || Map.get(assigns.rest, :"phx-target"), content_id: ${tooltip ? '"radix-" <> assigns.id <> "-content"' : 'assigns.id <> "-content"'}, trigger_id: assigns.id <> "-trigger", open: assigns.open, state: ${state}, dir: assigns.dir, side: assigns.side, align: assigns.align${select ? ', value: assigns.value, position: assigns.position, label: Enum.find_value(assigns.option, fn option -> if option.value == assigns.value, do: option.label end)' : ''}}
    ${select ? `markup = if assigns.open, do: ${root}_content(assign(assigns, :context, context))` : ''}
    trigger = %{
      "id" => context.trigger_id, "data-slot" => "${family}-trigger", "data-state" => context.state,
      "phx-hook" => "ShadcnLiveview.Components.${spec.moduleName}.Popup", "phx-popup-id" => assigns.id, "phx-popup-kind" => "${family}", "phx-popup-content-id" => context.content_id,
      "phx-popup-disabled" => to_string(assigns.disabled),
      "phx-target" => context.target,
      "phx-popup-offset" => assigns.side_offset, "phx-popup-open-delay" => assigns.open_delay,
      "phx-popup-close-delay" => assigns.close_delay, "phx-popup-event" => assigns.on_change${select ? ', "phx-popup-value" => assigns.value, "phx-popup-placeholder" => assigns.placeholder, "phx-popup-options" => Jason.encode!(Enum.map(assigns.option, fn option -> %{value: option.value, label: option.label, disabled: Map.get(option, :disabled, false)} end))' : ''}
    }
    trigger = Map.merge(trigger, ${family === "context-menu" ? '%{"style" => "-webkit-touch-callout:none", "data-disabled" => if(assigns.disabled, do: "")}' : hover ? '%{"disabled" => assigns.disabled}' : tooltip ? '%{"disabled" => assigns.disabled, "aria-describedby" => if(assigns.open, do: context.content_id)}' : `%{"type" => "button", "disabled" => assigns.disabled, "data-disabled" => ${family === "dropdown-menu" ? 'if(assigns.disabled, do: "")' : 'nil'}, "aria-haspopup" => "${select ? "listbox" : isMenu ? "menu" : "dialog"}", "aria-expanded" => to_string(assigns.open), "aria-controls" => if(assigns.open, do: context.content_id)}`})
    ${select ? 'trigger = trigger |> Map.delete("aria-haspopup") |> Map.merge(%{"role" => "combobox", "aria-autocomplete" => "none", "aria-required" => if(assigns.required, do: "true"), "dir" => assigns.dir, "data-disabled" => if(assigns.disabled, do: ""), "data-placeholder" => if(assigns.value in [nil, ""], do: "")})' : ''}
    assigns = assign(assigns, context: Map.put(context, :trigger, trigger)${select ? ', markup: markup' : ''})
    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @open do %>${select ? '{@markup}' : '{render_slot(@content, @context)}'}<% end %>
    ${select ? `<select name={@name} form={@form} disabled={@disabled} required={@required} aria-hidden="true" tabindex="-1" style="position:absolute;border:0;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;word-wrap:normal"><option :if={is_nil(@value)} value="" selected=""></option></select>` : ''}
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Popup">${hook}
    </script>
    """
  end
`
  if (select) source += selectComponents(cls)
  else source += `
  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def ${root}_content(assigns) do
    ~H"""
    <div data-radix-popper-content-wrapper="" style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:" dir={${isMenu ? '@context.dir' : 'nil'}}>
      <div id={@context.content_id} data-side={@context.side} data-align={@context.align} data-state={@context.state} data-slot="${family}-content"
        role={${isMenu ? '"menu"' : tooltip ? '"tooltip"' : hover ? 'nil' : '"dialog"'}} tabindex={${isMenu || family === "popover" ? '"-1"' : 'nil'}}
        aria-orientation={${isMenu ? '"vertical"' : 'nil'}} aria-labelledby={${family === "dropdown-menu" ? '@context.trigger_id' : 'nil'}}
        data-radix-menu-content={${isMenu ? '""' : 'nil'}} data-orientation={${isMenu ? '"vertical"' : 'nil'}} dir={${isMenu ? '@context.dir' : 'nil'}}
        class={classes([${contentClass}, @class])} style={content_style()} {@rest}>
        {render_slot(@inner_block)}
        ${tooltip ? `<span phx-popup-arrow="" style={arrow_style(@context.side)}><svg class="z-50 size-2.5 translate-y-[calc(-50%_-_2px)] rotate-45 rounded-[2px] bg-foreground fill-foreground" style="display:block" width="10" height="5" viewBox="0 0 30 10" preserveAspectRatio="none"><polygon points="0,0 30,0 15,10"></polygon></svg></span>` : ''}
      </div>
    </div>
    """
  end

  defp content_style do
    "${isMenu ? 'outline:none;' : ''}--radix-${family}-content-transform-origin:var(--radix-popper-transform-origin);--radix-${family}-content-available-width:var(--radix-popper-available-width);--radix-${family}-content-available-height:var(--radix-popper-available-height);--radix-${family}-trigger-width:var(--radix-popper-anchor-width);--radix-${family}-trigger-height:var(--radix-popper-anchor-height);animation:none"
  end
`
  if (tooltip) source += `
  defp arrow_style("top"), do: "position:absolute;bottom:0;transform:translateY(100%);visibility:hidden"
  defp arrow_style("bottom"), do: "position:absolute;top:0;transform-origin:center 0;transform:rotate(180deg);visibility:hidden"
  defp arrow_style("left"), do: "position:absolute;right:0;transform-origin:100% 0;transform:translateY(50%) rotate(-90deg) translateX(50%);visibility:hidden"
  defp arrow_style("right"), do: "position:absolute;left:0;transform-origin:0 0;transform:translateY(50%) rotate(90deg) translateX(-50%);visibility:hidden"
`
  if (isMenu) source += menuComponents(root, family, cls)
  if (family === "context-menu") source += `
  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def context_menu_trigger(assigns) do
    ~H"""
    <span class={classes(["select-none", @class])} {@context.trigger} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
`
  if (tooltip) source += `
  slot :inner_block, required: true
  def tooltip_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end
`
  for (const fn of spec.functions) {
    if ([root, `${root}_trigger`, `${root}_content`, `${root}_provider`].includes(fn.name) || isMenu || select) continue
    source += simple(fn.name, fn.slotName, fn.tag, cls(fn.name))
  }
  return source + "end\n"
}

function simple(name: string, slot: string, tag: string, cls: string, attributes = ""): string {
  return `
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block
  def ${name}(assigns) do
    ~H"""
    <${tag} data-slot="${slot}" class={classes([${cls}, @class])} ${attributes} {@rest}>{render_slot(@inner_block)}</${tag}>
    """
  end
`
}

function menuComponents(root: string, family: string, cls: (name: string) => string): string {
  let result = `
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: false
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id)
  slot :inner_block, required: true
  def ${root}_item(assigns) do
    ~H"""
    <div role="menuitem" aria-disabled={if @disabled, do: "true"} data-disabled={if @disabled, do: ""} data-slot="${family}-item" data-variant={@variant} data-inset={if @inset, do: "true"} class={classes([${cls(`${root}_item`)}, @class])} tabindex="-1" data-orientation="vertical" phx-popup-value={@value} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
`
  for (const type of ["checkbox", "radio"]) result += `
  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: false
  attr :value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id)
  slot :inner_block, required: true
  def ${root}_${type}_item(assigns) do
    ~H"""
    <div role="menuitem${type}" aria-checked={to_string(@checked)} aria-disabled={if @disabled, do: "true"} data-state={if @checked, do: "checked", else: "unchecked"} data-disabled={if @disabled, do: ""} data-inset={if @inset, do: "true"} data-slot="${family}-${type}-item" class={classes([${cls(`${root}_${type}_item`)}, @class])} tabindex="-1" data-orientation="vertical" phx-popup-value={@value} {@rest}>
      <span class="${family === "context-menu" ? 'pointer-events-none absolute right-2' : 'pointer-events-none absolute right-2 flex items-center justify-center'}" data-slot={${family === "context-menu" ? 'nil' : `"${family}-${type}-item-indicator"`}}><span :if={@checked} data-state="checked"><Icon.icon name="check" /></span></span>{render_slot(@inner_block)}
    </div>
    """
  end
`
  result += `
  attr :inset, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def ${root}_label(assigns) do
    ~H"""
    <div data-slot="${family}-label" data-inset={if @inset, do: "true"} class={classes([${cls(`${root}_label`)}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
`
  result += simple(`${root}_separator`, `${family}-separator`, "div", cls(`${root}_separator`), 'role="separator" aria-orientation="horizontal"')
  result += simple(`${root}_shortcut`, `${family}-shortcut`, "span", cls(`${root}_shortcut`))
  result += simple(`${root}_group`, `${family}-group`, "div", '""', 'role="group"')
  result += simple(`${root}_radio_group`, `${family}-radio-group`, "div", '""', 'role="group"')
  return result
}

function selectComponents(cls: (name: string) => string): string {
  return `
  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :rest, :global
  slot :inner_block, required: true
  def select_trigger(assigns) do
    ~H"""
    <button data-size={@size} class={classes([${cls("select_trigger")}, @class])} {@context.trigger} {@rest}>{render_slot(@inner_block)}<Icon.icon name="chevron-down" class="pointer-events-none size-4 text-muted-foreground" /></button>
    """
  end

  attr :context, :map, default: nil
  attr :placeholder, :string, default: ""
  slot :inner_block
  def select_value(assigns) do
    ~H"""
    <span data-slot="select-value" style="pointer-events:none"><%= if @inner_block == [] do %>{(@context && @context.label) || @placeholder}<% else %>{render_slot(@inner_block)}<% end %></span>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true
  attr :group, :list, default: []
  def select_content(assigns) do
    ~H"""
    <div :if={@context.position == "item-aligned"} style="display:flex;flex-direction:column;position:fixed">
      <.select_listbox context={@context} option={@option} group={@group} />
    </div>
    <div :if={@context.position == "popper"} data-radix-popper-content-wrapper="" style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:" dir={@context.dir}>
      <.select_listbox context={@context} option={@option} group={@group} />
    </div>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true
  attr :group, :list, default: []
  defp select_listbox(assigns) do
    assigns = assign(assigns, :options_by_group, Enum.group_by(assigns.option, &Map.get(&1, :group)))
    ~H"""
    <div role="listbox" id={@context.content_id} data-state="open" dir={@context.dir} data-side={if @context.position == "popper", do: @context.side} data-align={if @context.position == "popper", do: @context.align} data-slot="select-content" data-align-trigger={to_string(@context.position == "item-aligned")} class={classes([${cls("select_content")}, if(@context.position == "popper", do: "data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1")])} style={if @context.position == "item-aligned", do: "box-sizing:border-box;max-height:100%;display:flex;flex-direction:column;outline:none", else: "box-sizing:border-box;display:flex;flex-direction:column;outline:none;--radix-select-content-transform-origin:var(--radix-popper-transform-origin);--radix-select-content-available-width:var(--radix-popper-available-width);--radix-select-content-available-height:var(--radix-popper-available-height);--radix-select-trigger-width:var(--radix-popper-anchor-width);--radix-select-trigger-height:var(--radix-popper-anchor-height);animation:none"} tabindex="-1">
      <style>[data-radix-select-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-select-viewport]::-webkit-scrollbar{display:none}</style>
      <div data-radix-select-viewport="" role="presentation" data-position={@context.position} class="data-[position=popper]:h-(--radix-select-trigger-height) data-[position=popper]:w-full data-[position=popper]:min-w-(--radix-select-trigger-width)" style="position:relative;flex:1;overflow:hidden auto">
        <.select_options context={@context} option={Map.get(@options_by_group, nil, [])} />
        <div :for={group <- @group} role="group" aria-labelledby={"radix-" <> @context.id <> "-" <> group.id <> "-label"} data-slot="select-group" class={${cls("select_group")}}>
          <div id={"radix-" <> @context.id <> "-" <> group.id <> "-label"} data-slot="select-label" class={${cls("select_label")}}>{group.label}</div>
          <.select_options context={@context} option={Map.get(@options_by_group, group.id, [])} />
        </div>
      </div>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true
  defp select_options(assigns) do
    ~H"""
    <div :for={option <- @option} id={option.id} role="option" aria-labelledby={"radix-" <> option.id <> "-text"} aria-selected="false" data-state={if @context.value == option.value, do: "checked", else: "unchecked"} aria-disabled={if Map.get(option, :disabled, false), do: "true"} data-disabled={if Map.get(option, :disabled, false), do: ""} tabindex={if !Map.get(option, :disabled, false), do: "-1"} data-slot="select-item" class={classes([${cls("select_item")}, Map.get(option, :class)])} phx-popup-value={option.value}>
      <span class="pointer-events-none absolute right-2 flex size-4 items-center justify-center"><span :if={@context.value == option.value} aria-hidden="true"><Icon.icon name="check" class="pointer-events-none" /></span></span>
      <span id={"radix-" <> option.id <> "-text"}>{render_slot(option)}</span>
    </div>
    """
  end
`
}
