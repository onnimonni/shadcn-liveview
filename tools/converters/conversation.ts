import type { ComponentSpec } from "../generate"
import { buttonVariants } from "../../vendor/shadcn/ui/button"
import { cn } from "cn"
import { messageScrollerHook, questionnaireHook } from "./conversation-hooks"

const quoted = (value: string) => `~S|${value}|`
const attrs = `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)`
const slot = `  slot :inner_block`
const buttonSizes = ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"] as const
const buttonVariantsList = ["default", "outline", "secondary", "ghost", "destructive", "link"] as const

function buttonClasses(extra: string): string {
  return `  @button_classes %{
${buttonVariantsList.flatMap(variant => buttonSizes.map(size => `    {"${variant}", "${size}"} => ${quoted(cn(buttonVariants({ variant, size }), extra))}`)).join(",\n")}
  }

  defp button_classes(variant, size), do: Map.fetch!(@button_classes, {variant, size})`
}

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (!["message-scroller", "questionnaire"].includes(spec.name)) return undefined
  const cls = (name: string) => quoted(spec.functions.find(fn => fn.name === name)?.baseClasses ?? "")
  const simple = (name: string, tag: string) => `${attrs}
${slot}
  def ${name}(assigns) do
    ~H"""
    <${tag} data-slot="${name.replaceAll("_", "-")}" class={classes([${cls(name)}, @class])} {@rest}>{render_slot(@inner_block)}</${tag}>
    """
  end`
  const body = spec.name === "message-scroller" ? scroller(cls) : questionnaire(cls, simple)
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  ${spec.name === "message-scroller" ? "Message stream scrolling with explicit provider context and a native viewport hook. Pass provider context through :let to every child. Initial end/last-anchor positioning is pending until mounted; the hook clears pending after measuring, preserves prepends, follows new messages only while at the end, and cleans up observers." : "Caller-controlled questionnaire state with explicit root and item :let contexts. Supply items (name, required, disabled and choices maps), an optional item name, statuses and invalid names. The native form hook initializes controls, validates all enabled questions, supports keyboard navigation, resets answers, and dispatches questionnaire:item-change plus an optional LiveView on_item_change event. Server patches remain authoritative; hidden fieldsets are inert, not disabled, so answered questions remain in FormData."}
  ${spec.name === "questionnaire" ? "Hook navigation and reset events honor phx-target on the form or nearest containing element. Scalar forms use Phoenix's native form transport. Forms with multiple-answer items push configured phx-change/phx-submit events with array values, preserving successful DOM field names; changes include _target and an empty array when the last choice is cleared." : "The scrolling hook emits no LiveView events; native child events retain their caller-supplied Phoenix bindings and targets."}
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

${body}
end
`
}

function scroller(cls: (name: string) => string): string {
  return `  @doc "Provides explicit scrolling configuration without adding a wrapper element."
  attr :auto_scroll, :boolean, default: false
  attr :default_scroll_position, :string, values: ~w(start end last-anchor), default: "end"
  attr :scroll_edge_threshold, :integer, default: 8
  attr :scroll_previous_item_peek, :integer, default: 64
  attr :scroll_margin, :integer, default: 0
${slot}
  def message_scroller_provider(assigns) do
    context = Map.take(assigns, [:auto_scroll, :default_scroll_position, :scroll_edge_threshold, :scroll_previous_item_peek, :scroll_margin])
    assigns = assign(assigns, :context, context)
    ~H"""
    {render_slot(@inner_block, @context)}
    """
  end

  @doc "Scrollable root; id is stable and context comes from message_scroller_provider."
  attr :id, :string, required: true
  attr :context, :map, required: true
${attrs}
${slot}
  def message_scroller(assigns) do
    assigns = assign(assigns, :pending, assigns.context.default_scroll_position != "start")
    ~H"""
    <div id={@id} data-slot="message-scroller" data-pending-scroll={if @pending, do: ""}
      phx-hook=".MessageScroller" phx-value-position={@context.default_scroll_position}
      phx-value-auto-scroll={to_string(@context.auto_scroll)} phx-value-threshold={@context.scroll_edge_threshold}
      phx-value-peek={@context.scroll_previous_item_peek} phx-value-margin={@context.scroll_margin}
      class={classes([${cls("message_scroller")}, @class])} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MessageScroller">
${messageScrollerHook}
    </script>
    """
  end

  attr :context, :map, required: true
  attr :preserve_scroll_on_prepend, :boolean, default: true
${attrs}
${slot}
  def message_scroller_viewport(assigns) do
    ~H"""
    <div data-slot="message-scroller-viewport" role="region" aria-label="Messages" tabindex="0"
      data-pending-scroll={if @context.default_scroll_position != "start", do: ""}
      phx-value-preserve-prepend={to_string(@preserve_scroll_on_prepend)}
      class={classes([${cls("message_scroller_viewport")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :spacer_class, :string, default: nil
${attrs}
${slot}
  def message_scroller_content(assigns) do
    ~H"""
    <div data-slot="message-scroller-content" role="log" aria-relevant="additions" class={classes([${cls("message_scroller_content")}, @class])} {@rest}>
      {render_slot(@inner_block)}<div aria-hidden="true" data-message-scroller-spacer="" hidden class={@spacer_class}></div>
    </div>
    """
  end

  attr :message_id, :string, default: nil
  attr :scroll_anchor, :boolean, default: false
${attrs}
${slot}
  def message_scroller_item(assigns) do
    ~H"""
    <div data-slot="message-scroller-item" data-message-id={@message_id} data-scroll-anchor={to_string(@scroll_anchor)} class={classes([${cls("message_scroller_item")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :direction, :string, values: ~w(start end), default: "end"
  attr :behavior, :string, values: ~w(auto instant smooth), default: "smooth"
  attr :active, :boolean, default: false
  attr :variant, :string, default: "secondary"
  attr :size, :string, default: "icon-sm"
  attr :tabindex, :integer, default: nil
${attrs}
${slot}
  def message_scroller_button(assigns) do
    ~H"""
    <button data-slot="message-scroller-button" data-active={to_string(@active)} data-direction={@direction}
      data-variant={@variant} data-size={@size} type="button" inert={!@active} tabindex={if @active, do: @tabindex, else: -1}
      phx-value-tabindex={@tabindex} phx-value-behavior={@behavior}
      class={classes([button_classes(@variant, @size), @class])} {@rest}>
      <%= if @inner_block == [] do %><Icon.icon name="arrow_down" /><span class="sr-only">{if @direction == "end", do: "Scroll to end", else: "Scroll to start"}</span><% else %>{render_slot(@inner_block)}<% end %>
    </button>
    """
  end

${buttonClasses("absolute inset-s-1/2 -translate-x-1/2 border-border bg-background text-foreground transition-[translate,scale,opacity] duration-200 hover:bg-muted hover:text-foreground data-[active=false]:pointer-events-none data-[active=false]:scale-95 data-[active=false]:opacity-0 data-[active=false]:duration-400 data-[active=false]:ease-[cubic-bezier(0.7,0,0.84,0)] data-[active=true]:translate-y-0 data-[active=true]:scale-100 data-[active=true]:opacity-100 data-[active=true]:ease-[cubic-bezier(0.23,1,0.32,1)] data-[direction=end]:bottom-4 data-[direction=end]:data-[active=false]:translate-y-full data-[direction=start]:top-4 data-[direction=start]:data-[active=false]:-translate-y-full rtl:translate-x-1/2 data-[direction=start]:[&_svg]:rotate-180")}`
}

function questionnaire(cls: (name: string) => string, simple: (name: string, tag: string) => string): string {
  const navigation = ["previous", "skip", "next", "submit"].map(action => `${attrs}
  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :tabindex, :integer, default: nil
  attr :variant, :string, default: "${["previous", "skip"].includes(action) ? "outline" : "default"}"
  attr :size, :string, default: "default"
${slot}
  def questionnaire_${action}(assigns) do
    context = assigns.context
    visible = ${action === "previous" ? "context.total > 1 and not context.first" : action === "skip" ? "context.required == false" : action === "next" ? "context.total > 1 and not context.last" : "context.total > 0 and context.last"}
    shortcut = if visible and not assigns.disabled and "${action}" in ~w(next submit), do: "Enter"
    assigns = assign(assigns, visible: visible, shortcut: shortcut)
    ~H"""
    <button data-slot="questionnaire-${action}" data-disabled={if @disabled, do: ""}
      data-shortcut={@shortcut} data-status={@context.status} data-visible={if @visible, do: ""} data-hidden={if !@visible, do: ""}
      data-size={@size} data-variant={@variant} aria-hidden={if !@visible, do: "true"} aria-keyshortcuts={@shortcut}
      disabled={@disabled} hidden={!@visible} inert={!@visible} tabindex={if @visible, do: @tabindex, else: -1} phx-value-tabindex={@tabindex} type="${action === "submit" ? "submit" : "button"}"
      class={classes([button_classes(@variant, @size), "col-start-${action === "previous" ? 1 : action === "skip" ? 2 : 3} row-start-1 min-h-11 justify-self-${action === "previous" ? "start" : "end"} sm:min-h-0", @class])} {@rest}>
      <%= if @inner_block == [] do %>${action[0].toUpperCase() + action.slice(1)}<% else %>{render_slot(@inner_block)}<% end %>
    </button>
    """
  end`).join("\n\n")
  return `  @doc "Renders a native form and yields a context for steps, progress and navigation."
  attr :id, :string, required: true
  attr :items, :list, default: []
  attr :item, :string, default: nil
  attr :statuses, :map, default: %{}
  attr :invalid, :list, default: []
  attr :shortcuts, :string, values: [nil, "letters", "numbers"], default: nil
  attr :on_item_change, :string, default: nil
  attr :no_validate, :boolean, default: true
${attrs}
${slot}
  def questionnaire(assigns) do
    enabled = Enum.reject(assigns.items, &Map.get(&1, :disabled, false))
    item = assigns.item || (List.first(enabled) || %{})[:name]
    index = Enum.find_index(enabled, &(&1.name == item))
    current = if is_nil(index), do: 0, else: index + 1
    total = length(enabled)
    definition = Enum.find(enabled, &(&1.name == item))
    context = %{id: assigns.id, item: item, current: current, total: total, first: current == 1, last: total > 0 and current == total,
      required: if(definition, do: Map.get(definition, :required, false)), status: if(definition, do: Map.get(assigns.statuses, item, "unanswered")),
      statuses: assigns.statuses, invalid: assigns.invalid, shortcuts: assigns.shortcuts, items: assigns.items}
    assigns = assign(assigns, :context, context)
    ~H"""
    <form id={@id} data-slot="questionnaire" data-current={@context.current} data-total={@context.total}
      data-first={if @context.first, do: ""} data-last={if @context.last, do: ""} data-shortcuts={@shortcuts}
      novalidate={@no_validate} phx-hook=".Questionnaire" phx-value-item={@context.item} phx-value-on-item-change={@on_item_change}
      class={classes([${cls("questionnaire")}, @class])} {@rest}>{render_slot(@inner_block, @context)}</form>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Questionnaire">
      ${questionnaireHook}
    </script>
    """
  end

  attr :context, :map, required: true
${attrs}
${slot}
  def questionnaire_progress(assigns) do
    assigns = assign(assigns, :text, if(assigns.context.total > 0, do: "Question #{assigns.context.current} of #{assigns.context.total}"))
    ~H"""
    <div data-slot="questionnaire-progress" data-current={@context.current} data-total={@context.total} phx-value-custom={to_string(@inner_block != [])}
      data-first={if @context.first, do: ""} data-last={if @context.last, do: ""} role="progressbar" aria-label="Questionnaire progress" aria-live="polite"
      aria-valuemin={if @context.total > 0, do: 1} aria-valuemax={if @context.total > 0, do: @context.total}
      aria-valuenow={if @context.total > 0, do: @context.current} aria-valuetext={@text}
      class={classes([${cls("questionnaire_progress")}, @class])} {@rest}><%= if @inner_block == [] do %>{@text}<% else %>{render_slot(@inner_block, @context)}<% end %></div>
    """
  end

  @doc "A valid fieldset with explicit name and item state, yielding context for answer controls."
  attr :context, :map, required: true
  attr :name, :string, required: true
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :multiple, :boolean, default: false
  attr :invalid, :boolean, default: false
  attr :status, :string, default: nil, values: [nil, "unanswered", "answered", "skipped"]
${attrs}
${slot}
  def questionnaire_item(assigns) do
    active = not assigns.disabled and assigns.context.item == assigns.name
    status = assigns.status || Map.get(assigns.context.statuses, assigns.name, "unanswered")
    invalid = not assigns.disabled and status != "skipped" and (assigns.invalid or assigns.name in assigns.context.invalid)
    keys = item_keyshortcuts(active, assigns.context, status)
    context = Map.merge(assigns.context, %{name: assigns.name, active: active, disabled: assigns.disabled, required: assigns.required, multiple: assigns.multiple, invalid: invalid, status: status})
    assigns = assign(assigns, context: context, keys: keys)
    ~H"""
    <fieldset data-slot="questionnaire-item" data-active={if @context.active, do: ""} data-disabled={if @disabled, do: ""}
      data-invalid={if @context.invalid, do: ""} data-multiple={if @multiple, do: ""} data-required={if @required, do: ""} data-status={@context.status}
      phx-value-name={@name} phx-value-server-status={@context.status} phx-value-server-invalid={to_string(@context.invalid)}
      disabled={@disabled} hidden={!@context.active} inert={!@context.active} tabindex="-1"
      aria-invalid={if @context.invalid, do: "true"} aria-keyshortcuts={@keys}
      class={classes([${cls("questionnaire_item")}, @class])} {@rest}>{render_slot(@inner_block, @context)}</fieldset>
    """
  end

  defp item_keyshortcuts(false, _context, _status), do: nil

  defp item_keyshortcuts(true, context, status) do
    [
      "Meta+Enter Control+Enter",
      if(!context.first, do: "ArrowLeft"),
      if(!context.last and status != "unanswered", do: "ArrowRight")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

${simple("questionnaire_title", "legend")}

  attr :id, :string, required: true
${attrs}
${slot}
  def questionnaire_description(assigns) do
    ~H"""
    <p id={@id} data-slot="questionnaire-description" class={classes([${cls("questionnaire_description")}, @class])} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  attr :context, :map, required: true
${attrs}
${slot}
  def questionnaire_choices(assigns) do
    ~H"""
    <div data-slot="questionnaire-choices" data-shortcuts={@context.shortcuts} class={classes([${cls("questionnaire_choices")}, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Native radio/checkbox answer, with stable input identity and caller-supplied choice index for shortcuts."
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :id, :string, default: nil
  attr :index, :integer, default: 0
  attr :checked, :boolean, default: false
  attr :default_checked, :boolean, default: false
  attr :disabled, :boolean, default: false
${attrs}
${slot}
  def questionnaire_choice(assigns) do
    disabled = assigns.disabled or assigns.context.disabled
    shortcut = choice_shortcut(assigns.context.shortcuts, assigns.index, disabled)
    type = if assigns.context.multiple, do: "checkbox", else: "radio"
    id = assigns.id || "radix-#{assigns.context.id}-#{assigns.context.name}-#{assigns.value}"
    keys = Enum.join(Enum.reject([shortcut, if(!disabled and assigns.checked, do: "Enter")], &is_nil/1), " ")
    assigns = assign(assigns, disabled: disabled, shortcut: shortcut, type: type, input_id: id, keys: if(keys != "", do: keys))
    ~H"""
    <label data-slot="questionnaire-choice" data-checked={if @checked, do: ""} data-unchecked={if !@checked, do: ""}
      data-disabled={if @disabled, do: ""} data-invalid={if @context.invalid, do: ""} data-shortcut={@shortcut} data-type={@type}
      class={classes([${quoted(choiceClasses)}, @class])} {@rest}>
      <input id={@input_id} data-slot="questionnaire-choice-input" data-checked={if @checked, do: ""} data-unchecked={if !@checked, do: ""}
        data-disabled={if @disabled, do: ""} data-invalid={if @context.invalid, do: ""} data-shortcut={@shortcut} data-type={@type}
        class="absolute inset-0 z-10 size-full cursor-pointer opacity-0" aria-invalid={if @context.invalid, do: "true"} aria-keyshortcuts={@keys}
        checked={@checked} disabled={@disabled} name={if @context.status != "skipped", do: @context.name}
        required={@context.required and not @context.multiple} type={@type} value={@value} phx-value-default-checked={to_string(@default_checked)} />
      <span aria-hidden="true" data-slot="questionnaire-choice-indicator" class=${JSON.stringify(indicatorClasses)}>
        <span data-slot="questionnaire-choice-indicator-dot" class="hidden size-2 rounded-full bg-primary-foreground group-data-[type=checkbox]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block"></span>
        <Icon.icon name="check" data-slot="questionnaire-choice-indicator-check" class="hidden size-3.5 group-data-[type=radio]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block" />
      </span>
      <span data-slot="questionnaire-choice-label" class="flex min-w-0 flex-1 flex-col gap-0.5 leading-snug">{render_slot(@inner_block)}</span>
      <span data-slot="questionnaire-choice-shortcut" data-shortcut={@shortcut} aria-hidden="true" hidden={is_nil(@shortcut)} class=${JSON.stringify(shortcutClasses)}>{@shortcut}</span>
    </label>
    """
  end

  defp choice_shortcut("letters", index, false) when index >= 0 and index < 26, do: <<65 + index>>
  defp choice_shortcut("numbers", index, false) when index >= 0 and index < 9, do: Integer.to_string(index + 1)
  defp choice_shortcut(_mode, _index, _disabled), do: nil

${simple("questionnaire_choice_description", "span")}

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text"
  attr :disabled, :boolean, default: false
${attrs}
  def questionnaire_input(assigns) do
    filled = not is_nil(assigns.value) and String.trim(to_string(assigns.value)) != ""
    assigns = assign(assigns, filled: filled, disabled: assigns.disabled or assigns.context.disabled,
      input_id: assigns.id || "radix-#{assigns.context.id}-#{assigns.context.name}-input")
    ~H"""
    <div data-slot="questionnaire-input-wrapper" class="group/questionnaire-input relative w-full min-w-0">
      <input id={@input_id} data-slot="questionnaire-input" data-disabled={if @disabled, do: ""}
        data-filled={if @filled, do: ""} data-empty={if !@filled, do: ""} data-invalid={if @context.invalid, do: ""}
        aria-invalid={if @context.invalid, do: "true"} disabled={@disabled} form="" type={@type} value={@value}
        class={classes([${cls("questionnaire_input")}, @class])} {@rest} />
    </div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
${attrs}
${slot}
  def questionnaire_error(assigns) do
    ~H"""
    <p id={@id} data-slot="questionnaire-error" data-invalid={if @context.invalid, do: ""} hidden={!@context.invalid}
      role={if @context.invalid, do: "alert"} class={classes([${cls("questionnaire_error")}, @class])} {@rest}>
      <%= if @inner_block == [] do %>{if @context.required, do: "Choose an answer to continue.", else: "Choose an answer or skip this question."}<% else %>{render_slot(@inner_block)}<% end %>
    </p>
    """
  end

${simple("questionnaire_actions", "div")}

${navigation}

${buttonClasses("")}`
}

const choiceClasses = "group/questionnaire-choice relative flex min-h-11 cursor-pointer items-start gap-2.5 rounded-lg border border-input bg-transparent px-3 py-2.5 text-start text-sm transition-colors outline-none select-none hover:bg-muted/50 has-[>input:focus-visible]:border-ring has-[>input:focus-visible]:ring-3 has-[>input:focus-visible]:ring-ring/50 data-invalid:border-destructive dark:bg-input/20 data-checked:border-primary/40 data-checked:bg-muted dark:data-checked:bg-muted data-disabled:pointer-events-none data-disabled:cursor-not-allowed data-disabled:opacity-50"
const indicatorClasses = "pointer-events-none relative flex size-4 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-[4px] border border-input group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[type=radio]/questionnaire-choice:rounded-full group-data-checked/questionnaire-choice:border-primary group-data-checked/questionnaire-choice:bg-primary group-data-checked/questionnaire-choice:text-primary-foreground dark:bg-input/30 dark:group-data-checked/questionnaire-choice:bg-primary"
const shortcutClasses = "pointer-events-none ms-auto hidden size-5 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-md border border-input bg-background font-mono text-[0.625rem] leading-none font-medium text-muted-foreground group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[shortcut]/questionnaire-choice:inline-flex"

