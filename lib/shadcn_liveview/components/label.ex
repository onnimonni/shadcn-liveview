defmodule ShadcnLiveview.Components.Label do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def label(assigns) do
    ~H"""
    <label
      data-slot="label"
      class={classes(["flex items-center gap-2 text-sm leading-none font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end
end
