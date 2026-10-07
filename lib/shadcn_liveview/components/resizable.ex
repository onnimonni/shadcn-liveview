defmodule ShadcnLiveview.Components.Resizable do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def resizable_panel_group(assigns) do
    ~H"""
    <div
      data-slot="resizable-panel-group"
      class={classes(["flex h-full w-full aria-[orientation=vertical]:flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def resizable_panel(assigns) do
    ~H"""
    <div
      data-slot="resizable-panel"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def resizable_handle(assigns) do
    ~H"""
    <div
      data-slot="resizable-handle"
      class={classes(["z-10 flex h-6 w-1 shrink-0 rounded-lg bg-border", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
