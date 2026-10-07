defmodule ShadcnLiveview.Components.NativeSelect do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def native_select(assigns) do
    ~H"""
    <div
      data-slot="native-select-icon" data-size={@size}
      class={classes(["pointer-events-none absolute top-1/2 right-2.5 size-4 -translate-y-1/2 text-muted-foreground select-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def native_select_option(assigns) do
    ~H"""
    <div
      data-slot="native-select-option"
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def native_select_opt_group(assigns) do
    ~H"""
    <div
      data-slot="native-select-optgroup"
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
