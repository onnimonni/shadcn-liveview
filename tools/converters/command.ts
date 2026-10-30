import type { ComponentSpec } from "../generate"
import { commandHook, otpHook, comboboxHook } from "./command-hooks"

const q = (value: string) => JSON.stringify(value)
const group = "group/input-group relative flex h-8 w-full min-w-0 items-center rounded-lg border border-input transition-colors outline-none in-data-[slot=combobox-content]:focus-within:border-inherit in-data-[slot=combobox-content]:focus-within:ring-0 has-disabled:bg-input/50 has-disabled:opacity-50 has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-3 has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50 has-[[data-slot][aria-invalid=true]]:border-destructive has-[[data-slot][aria-invalid=true]]:ring-3 has-[[data-slot][aria-invalid=true]]:ring-destructive/20 has-[>[data-align=block-end]]:h-auto has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-start]]:h-auto has-[>[data-align=block-start]]:flex-col has-[>textarea]:h-auto dark:bg-input/30 dark:has-disabled:bg-input/80 dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40 has-[>[data-align=block-end]]:[&>input]:pt-3 has-[>[data-align=block-start]]:[&>input]:pb-3 has-[>[data-align=inline-end]]:[&>input]:pr-1.5 has-[>[data-align=inline-start]]:[&>input]:pl-1.5"
const addon = "flex h-auto cursor-text items-center justify-center gap-2 py-1.5 text-sm font-medium text-muted-foreground select-none group-data-[disabled=true]/input-group:opacity-50 [&>kbd]:rounded-[calc(var(--radius)-5px)] [&>svg:not([class*='size-'])]:size-4"
const button = "group/button shrink-0 justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 flex items-center gap-2 text-sm shadow-none size-6 rounded-[calc(var(--radius)-3px)] p-0 has-[>svg]:p-0"
const input = "h-8 w-full min-w-0 border-input px-2.5 py-1 text-base transition-colors outline-none file:inline-flex file:h-6 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 md:text-sm dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 flex-1 rounded-none border-0 bg-transparent shadow-none ring-0 focus-visible:ring-0 disabled:bg-transparent aria-invalid:ring-0 dark:bg-transparent dark:disabled:bg-transparent"
const labelStyle = "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;border-width:0"
const hiddenStyle = "clip-path:inset(50%);overflow:hidden;white-space:nowrap;border:0;padding:0;width:1px;height:1px;margin:-1px;position:"

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name !== "command" && spec.name !== "combobox" && spec.name !== "input-otp") return undefined
  const cls = (name: string) => {
    const fn = spec.functions.find(fn => fn.name === name)
    if (!fn) throw new Error(`Missing ${spec.name} component function: ${name}`)
    return q(fn.baseClasses)
  }
  const header = (docs: string) => `defmodule ShadcnLiveview.Components.${spec.moduleName} do\n  @moduledoc ${q(docs)}\n  use Phoenix.Component\n  import ShadcnLiveview.Helpers\n  alias ShadcnLiveview.Components.Icon\n`
  if (spec.name === "command") return header("A command palette with explicit root context, native search inputs, and a colocated filtering/keyboard hook. Pass the root :let context to input and list. Items require stable IDs and explicit values. Filtering ranks items with CSS order while retaining server-owned DOM placement; keyboard navigation follows the same visual order. As in cmdk SSR, item registration and initial selection/filtering happen when the client mounts. on_select optionally pushes an event with id and value to the nearest phx-target ancestor, or the owning LiveView when absent; the search input retains native name/form semantics.") + `
  @doc "Renders a command root; :let receives its stable IDs and selected value."
  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :label, :string, default: ""
  attr :loop, :boolean, default: false
  attr :should_filter, :boolean, default: true
  attr :on_select, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, value: assigns.value, input_id: "radix-#{assigns.id}-input", label_id: "radix-#{assigns.id}-label", list_id: "radix-#{assigns.id}-list"})
    ~H"""
    <div id={@id} tabindex="-1" data-slot="command" cmdk-root="" class={classes([${cls("command")}, @class])} phx-hook=".Command" phx-value-selected={@value} phx-value-loop={to_string(@loop)} phx-value-filter={to_string(@should_filter)} phx-value-event={@on_select} {@rest}>
      <label cmdk-label="" for={@context.input_id} id={@context.label_id} style=${q(labelStyle)}>{@label}</label>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Command">
      ${commandHook}
    </script>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, default: ""
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(name form placeholder disabled required readonly autocomplete autocorrect spellcheck type)
  def command_input(assigns) do
    ~H"""
    <div data-slot="command-input-wrapper" class="p-1 pb-0">
      <div data-slot="input-group" role="group" class=${q(group.replace("border-input ", "") + " h-8! rounded-lg! border-input/30 bg-input/30 shadow-none! *:data-[slot=input-group-addon]:pl-2!")}>
        <input data-slot="command-input" class={classes([${cls("command_input")}, @class])} cmdk-input="" autocomplete="off" autocorrect="off" spellcheck="false" aria-autocomplete="list" role="combobox" aria-expanded="true" aria-controls={@context.list_id} aria-labelledby={@context.label_id} id={@context.input_id} type="text" value={@value} {@rest} />
        <div role="group" data-slot="input-group-addon" data-align="inline-start" class=${q(addon + " order-first pl-2 has-[>button]:ml-[-0.3rem] has-[>kbd]:ml-[-0.15rem]")}>
          <Icon.icon name="search" class="size-4 shrink-0 opacity-50" />
        </div>
      </div>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :label, :string, default: "Suggestions"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command_list(assigns) do
    ~H"""
    <div data-slot="command-list" class={classes([${cls("command_list")}, @class])} cmdk-list="" role="listbox" tabindex="-1" aria-label={@label} id={@context.list_id} {@rest}><div cmdk-list-sizer="">{render_slot(@inner_block)}</div></div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command_empty(assigns) do
    ~H"""
    <div data-slot="command-empty" class={classes([${cls("command_empty")}, @class])} cmdk-empty="" role="presentation" {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :id, :string, required: true
  attr :heading, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command_group(assigns) do
    ~H"""
    <div data-slot="command-group" class={classes([${cls("command_group")}, @class])} cmdk-group="" role="presentation" {@rest}>
      <div :if={@heading} cmdk-group-heading="" aria-hidden="true" id={"radix-#{@id}-heading"}>{@heading}</div>
      <div cmdk-group-items="" role="group" aria-labelledby={@heading && "radix-#{@id}-heading"}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Items are registered by the client hook; disabled items cannot be selected."
  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :keywords, :list, default: []
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command_item(assigns) do
    ~H"""
    <div data-slot="command-item" class={classes([${cls("command_item")}, @class])} id={@id} cmdk-item="" role="option" aria-disabled={to_string(@disabled)} aria-selected="false" data-disabled={to_string(@disabled)} data-selected="false" phx-value-value={@value} phx-value-keywords={Jason.encode!(@keywords)} {@rest}>
      {render_slot(@inner_block)}
      <Icon.icon name="check" class="ml-auto opacity-0 group-has-data-[slot=command-shortcut]/command-item:hidden group-data-[checked=true]/command-item:opacity-100" />
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  def command_separator(assigns) do
    ~H"""
    <div data-slot="command-separator" class={classes([${cls("command_separator")}, @class])} cmdk-separator="" role="separator" {@rest} />
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def command_shortcut(assigns) do
    ~H"""
    <span data-slot="command-shortcut" class={classes([${cls("command_shortcut")}, @class])} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
`
  if (spec.name === "input-otp") return header("A single native OTP input with slotted visual cells. Root :let passes the value to each indexed slot. Native name, form, required, disabled, pattern and autocomplete semantics are retained. The colocated hook manages focus, character selection, paste, fake carets and completion. Declared minlength remains enforced through the native Constraint Validation API after LiveView value patches clear the browser user-edit flag; caller-owned custom validity is preserved. on_change/on_complete events receive id and value and route to the nearest phx-target ancestor, or the owning LiveView when absent. Completion waits for the final change acknowledgement before sending on_complete; paste_transform may be strip-separators. Without JavaScript the noscript CSS exposes the real input. With JavaScript the hook restores its adjacent noscript to text after fragment patches, preserving the browser scripting-enabled parsing invariant.") + `
  @no_script_css ${q(noScriptCSS)}
  @doc "Render indexed cells with :let and context; id belongs to the native input."
  attr :id, :string, required: true
  attr :max_length, :integer, required: true
  attr :value, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :pattern, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :input_mode, :string, default: "numeric"
  attr :text_align, :string, default: "left"
  attr :paste_transform, :string, default: nil, values: [nil, "strip-separators"]
  attr :on_change, :string, default: nil
  attr :on_complete, :string, default: nil
  attr :class, :any, default: nil
  attr :container_class, :string, default: nil
  attr :no_script_css, :string, default: @no_script_css
  attr :rest, :global, include: ~w(type name form required readonly autocomplete autofocus minlength title aria-label aria-describedby aria-invalid)
  slot :inner_block, required: true
  def input_otp(assigns) do
    assigns = assign(assigns, :context, %{value: assigns.value, max_length: assigns.max_length})
    ~H"""
    <noscript :if={@no_script_css}>{Phoenix.HTML.raw(["<style>", @no_script_css, "</style>"])}</noscript>
    <div data-input-otp-container="true" translate="no" style={"position:relative;cursor:" <> if(@disabled, do: "default", else: "text") <> ";user-select:none;-webkit-user-select:none;pointer-events:none"} class={classes(["cn-input-otp flex items-center has-disabled:opacity-50", @container_class])}>
      {render_slot(@inner_block, @context)}
      <div style="position:absolute;inset:0;pointer-events:none">
        <input id={@id} autocomplete="one-time-code" data-slot="input-otp" spellcheck="false" class={classes(["disabled:cursor-not-allowed", @class])} data-input-otp="true" data-input-otp-placeholder-shown={@value == "" && "true"} inputmode={@input_mode} pattern={@pattern} aria-placeholder={@placeholder} disabled={@disabled} maxlength={@max_length} value={@value} style={"position:absolute;inset:0;width:100%;height:100%;display:flex;text-align:" <> @text_align <> ";opacity:1;color:transparent;pointer-events:all;background:transparent;caret-color:transparent;border:0 solid transparent;outline:0 solid transparent;box-shadow:none;line-height:1;letter-spacing:-.5em;font-size:var(--root-height, 16px);font-family:monospace;font-variant-numeric:tabular-nums"} phx-hook=".InputOTP" phx-value-value={@value} phx-value-transform={@paste_transform} phx-value-change={@on_change} phx-value-complete={@on_complete} {@rest} />
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".InputOTP">
      ${otpHook}
    </script>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def input_otp_group(assigns) do
    ~H"""
    <div data-slot="input-otp-group" class={classes([${cls("input_otp_group")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :context, :map, required: true
  attr :index, :integer, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  def input_otp_slot(assigns) do
    ~H"""
    <div data-slot="input-otp-slot" data-active="false" class={classes([${cls("input_otp_slot")}, @class])} phx-value-index={@index} {@rest}>{String.at(@context.value, @index)}</div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  def input_otp_separator(assigns) do
    ~H"""
    <div data-slot="input-otp-separator" class={classes([${cls("input_otp_separator")}, @class])} role="separator" {@rest}><Icon.icon name="minus" /></div>
    """
  end
end
`
  if (spec.name === "combobox") return header("A native editable combobox with caller IDs and explicit selected/open assigns. Input and content named slots receive :let context. Closed content is absent, matching Base UI SSR; LiveView renders and owns the content after the caller handles shadcn:combobox-open with id/open. Pressing the editable input or its trigger opens the options. Handle shadcn:combobox-change with id/value to update selection and the clear affordance; pass input_value for the selected display label. Event names are configurable and route to the nearest phx-target ancestor of the editable input, or the owning LiveView when absent. The colocated hook filters and navigates existing server-owned items; it never copies or reparents slot markup. Group and popup ownership is refreshed after patches to independent roots. Disabling either the root or combobox_input disables the editable input, trigger and clear affordance on every server render. Native name/form, disabled and validation semantics stay on form controls.") + `
  @doc "Root is renderless; input/content named slots receive explicit state context."
  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :input_value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :open, :boolean, default: false
  attr :on_open_change, :string, default: "shadcn:combobox-open"
  attr :required, :boolean, default: false
  attr :on_change, :string, default: "shadcn:combobox-change"
  attr :rest, :global
  slot :input, required: true
  slot :content, required: true
  def combobox(assigns) do
    context = %{id: assigns.id, value: assigns.value, input_value: assigns.input_value || assigns.value, disabled: assigns.disabled, open: assigns.open, event: assigns.on_change, open_event: assigns.on_open_change, target: Map.get(assigns.rest, :"phx-target") || Map.get(assigns.rest, "phx-target"), list_id: "radix-#{assigns.id}-list", popup_id: "radix-#{assigns.id}-popup"}
    assigns = assign(assigns, :context, context)
    ~H"""
    {render_slot(@input, @context)}
    {if @open, do: render_slot(@content, @context)}
    <input id={is_nil(@name) && @id <> "-hidden-input"} disabled={@disabled} style={${q(hiddenStyle)} <> if(@name, do: "absolute", else: "fixed;top:0;left:0")} tabindex="-1" aria-hidden="true" name={@name} form={@form} required={@required} value={@value} />
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
  attr :disabled, :boolean, default: false
  attr :show_trigger, :boolean, default: true
  attr :show_clear, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type placeholder readonly required name form inputmode autocomplete aria-label aria-describedby aria-invalid)
  slot :inner_block
  def combobox_input(assigns) do
    assigns = assign(assigns, :effective_disabled, assigns.disabled || assigns.context.disabled)
    ~H"""
    <div data-slot="input-group" role="group" phx-target={@context.target} class={classes([${q(group.replace("w-full ", "") + " w-auto")}, @class])}>
      <input id={@id} data-slot="input-group-control" class=${q(input)} data-disabled={@effective_disabled && ""} data-list-empty="" autocomplete="off" spellcheck="false" autocorrect="off" autocapitalize="none" role="combobox" aria-expanded={to_string(@context.open)} aria-controls={@context.open && @context.list_id} aria-haspopup="listbox" aria-autocomplete="list" disabled={@effective_disabled} value={@context.input_value} phx-hook=".Combobox" phx-value-root={@context.id} phx-value-popup-id={@context.popup_id} phx-value-selected={@context.value} phx-value-event={@context.event} phx-value-open-event={@context.open_event} phx-value-open={to_string(@context.open)} {@rest} />
      <div role="group" data-slot="input-group-addon" data-align="inline-end" class=${q(addon + " order-last pr-2 has-[>button]:mr-[-0.3rem] has-[>kbd]:mr-[-0.15rem]")}>
        <button :if={@show_trigger} id={@context.id} type="button" data-disabled={@effective_disabled && ""} data-list-empty="" data-placeholder={@context.value == "" && ""} tabindex="0" role="combobox" aria-expanded={to_string(@context.open)} aria-haspopup="dialog" disabled={@effective_disabled} data-slot="input-group-button" data-variant="ghost" data-size="icon-xs" class=${q(button + " group-has-data-[slot=combobox-clear]/input-group:hidden data-pressed:bg-transparent")}><Icon.icon name="chevron-down" class="pointer-events-none size-4 text-muted-foreground" /></button>
        <.combobox_clear :if={@show_clear && @context.value != ""} disabled={@effective_disabled} />
      </div>
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Combobox">
      ${comboboxHook}
    </script>
    """
  end

  attr :disabled, :boolean, default: false
  defp combobox_clear(assigns) do
    ~H"""
    <button data-slot="combobox-clear" data-variant="ghost" data-size="icon-xs" class=${q(button)} type="button" data-disabled={@disabled && ""} data-visible="" tabindex="-1" disabled={@disabled}><Icon.icon name="x" class="pointer-events-none" /></button>
    """
  end

  attr :context, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_content(assigns) do
    ~H"""
    <div id={@context.popup_id} data-slot="combobox-content" data-chips="false" data-side="bottom" class={classes([${cls("combobox_content")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :context, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_list(assigns) do
    ~H"""
    <div id={@context.list_id} data-slot="combobox-list" role="listbox" class={classes([${cls("combobox_list")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_item(assigns) do
    ~H"""
    <div id={"radix-#{@context.id}-item-#{URI.encode(@value)}"} data-slot="combobox-item" role="option" aria-selected={to_string(@context.value == @value)} data-disabled={@disabled && ""} aria-disabled={to_string(@disabled)} phx-value-value={@value} class={classes([${cls("combobox_item")}, @class])} {@rest}>
      {render_slot(@inner_block)}
      <span hidden={@context.value != @value} class="pointer-events-none absolute right-2 flex size-4 items-center justify-center"><Icon.icon name="check" class="pointer-events-none" /></span>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_group(assigns) do
    ~H"""
    <div data-slot="combobox-group" class={classes([${cls("combobox_group")}, @class])} role="group" {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_label(assigns) do
    ~H"""
    <div data-slot="combobox-label" class={classes([${cls("combobox_label")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  def combobox_empty(assigns) do
    ~H"""
    <div data-slot="combobox-empty" class={classes([${cls("combobox_empty")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  def combobox_separator(assigns) do
    ~H"""
    <div data-slot="combobox-separator" role="separator" class={classes([${cls("combobox_separator")}, @class])} {@rest} />
    """
  end
end
`
  return undefined
}


const noScriptCSS = `
[data-input-otp] {
  --nojs-bg: white !important;
  --nojs-fg: black !important;

  background-color: var(--nojs-bg) !important;
  color: var(--nojs-fg) !important;
  caret-color: var(--nojs-fg) !important;
  letter-spacing: .25em !important;
  text-align: center !important;
  border: 1px solid var(--nojs-fg) !important;
  border-radius: 4px !important;
  width: 100% !important;
}
@media (prefers-color-scheme: dark) {
  [data-input-otp] {
    --nojs-bg: black !important;
    --nojs-fg: white !important;
  }
}`
