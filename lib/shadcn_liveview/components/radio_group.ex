defmodule ShadcnLiveview.Components.RadioGroup do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :default_value, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def radio_group(assigns) do
    ~H"""
    <div
      data-slot="radio-group"
      class={classes(["grid w-full gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def radio_group_item(assigns) do
    ~H"""
    <div
      data-slot="radio-group-indicator"
      class={classes(["absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
