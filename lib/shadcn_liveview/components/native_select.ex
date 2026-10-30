defmodule ShadcnLiveview.Components.NativeSelect do
  @moduledoc ~S"""
  A styled native `<select>` with options and option groups.

  Upstream: https://ui.shadcn.com/docs/components/radix/native-select

  Components: `native_select/1`, `native_select_option/1`, `native_select_opt_group/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.native_select>
    <.native_select_option value="1">Option 1</.native_select_option>
    <.native_select_option value="2">Option 2</.native_select_option>
  </.native_select>
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  @doc """
  Native select with a wrapper and decorative icon. `class` styles the wrapper;
  `size` is "default" or "sm". Native attributes (name, id, disabled,
  multiple, required, form, autocomplete and ARIA attributes) go on the select.

  `value` (controlled initial selection) takes precedence over `default_value`.
  Both accept a scalar or, for multiple selection, a list. Use
  `:let={selection}` on the inner slot and `selected={value in selection}`
  on each option to apply this normalized string list, including inside optgroups.

      <.native_select :let={selection} name="fruit" default_value="pear">
        <.native_select_option value="apple" selected={"apple" in selection}>Apple</.native_select_option>
        <.native_select_option value="pear" selected={"pear" in selection}>Pear</.native_select_option>
      </.native_select>

  Without a selection prop, the browser selects its native default.
  Subsequent user selection and form submission are handled by the native element;
  LiveView callers can supply phx-change and update value on subsequent renders.
  """
  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc:
      "Form field such as `@form[:email]`; supplies id, name and value. Explicit attributes win."

  attr :size, :string, default: "default", values: ~w(default sm)
  attr :value, :any, default: nil

  attr :default_value, :any,
    default: nil,
    doc: "Uncontrolled initial `value`; ignored once `value` is supplied."

  attr :rest, :global, include: ~w(name disabled multiple required form autofocus autocomplete)
  slot :inner_block, required: false

  def native_select(assigns) do
    assigns = ShadcnLiveview.Form.bind(assigns, :select)
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
  end

  @doc """
  Native option; forwards value, selected, disabled and label.
  Set selected from the native_select slot selection list when using value/default_value.
  """
  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(value selected disabled label)
  slot :inner_block, required: false

  def native_select_option(assigns) do
    ~H"""
    <option
      data-slot="native-select-option"
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </option>
    """
  end

  @doc """
  Native optgroup; forwards label and disabled.
  Nested options can use the enclosing native_select slot selection list.
  """
  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(label disabled)
  slot :inner_block, required: false

  def native_select_opt_group(assigns) do
    ~H"""
    <optgroup
      data-slot="native-select-optgroup"
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </optgroup>
    """
  end
end
