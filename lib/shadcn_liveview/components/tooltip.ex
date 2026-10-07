defmodule ShadcnLiveview.Components.Tooltip do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tooltip_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tooltip(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tooltip_trigger(assigns) do
    ~H"""
    <button
      data-slot="tooltip-trigger"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tooltip_content(assigns) do
    ~H"""
    <div
      data-slot="tooltip-content"
      class={classes(["z-50 size-2.5 translate-y-[calc(-50%_-_2px)] rotate-45 rounded-[2px] bg-foreground fill-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
