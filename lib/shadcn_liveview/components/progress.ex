defmodule ShadcnLiveview.Components.Progress do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  @doc """
  Progress matching the upstream wrapper: `value` controls only the indicator's
  visual percentage (nil/absent means zero). It is not passed to the Radix root,
  so both root and indicator remain indeterminate and omit aria-valuenow.
  `max` sets root/indicator data-max and aria-valuemax, defaulting to 100
  unless it is a positive number; it does not scale the visual percentage.
  `class` styles the root; global/ARIA attributes are forwarded to the root.
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
      class={
        classes([
          "relative flex h-1 w-full items-center overflow-x-hidden rounded-full bg-muted",
          @class
        ])
      }
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
  end
end
