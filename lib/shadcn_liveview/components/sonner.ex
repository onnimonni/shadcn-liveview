defmodule ShadcnLiveview.Components.Sonner do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def toaster(assigns) do
    ~H"""
    <div
      data-slot="toaster"
      class={classes(["size-4 animate-spin", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
