defmodule ShadcnLiveview.Components.Progress do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :value, :integer, default: 0
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
  end
end
