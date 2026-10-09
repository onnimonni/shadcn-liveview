import type { ComponentFunctionSpec } from "../generate"
import notifications from "./notifications"

function spinner(): string {
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

function nativeSelect(): string {
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

function nativeSelectOption(fn: ComponentFunctionSpec): string {
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

function progress(): string {
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


const templates: Record<string, () => string> = { spinner, native_select: nativeSelect, progress }

export function generateNativeFunction(fn: ComponentFunctionSpec): string | undefined {
  if (fn.name === "native_select_option" || fn.name === "native_select_opt_group") return nativeSelectOption(fn)
  if (fn.name === "sonner" || fn.name === "toaster") return notifications(fn)
  return Object.hasOwn(templates, fn.name) ? templates[fn.name]() : undefined
}
