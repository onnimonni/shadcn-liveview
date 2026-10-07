defmodule ShadcnLiveview.Components.Separator do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :orientation, :string, default: "horizontal"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def separator(assigns) do
    ~H"""
    <div
      data-slot="separator" data-orientation={@orientation} role="none"
      class={classes(["shrink-0 bg-border data-horizontal:h-px data-horizontal:w-full data-vertical:w-px data-vertical:self-stretch", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
