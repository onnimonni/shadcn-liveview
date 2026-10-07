defmodule ShadcnLiveview.Components.Direction do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def direction_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def use_direction(assigns) do
    ~H"""
    <div
      data-slot="use-direction"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
