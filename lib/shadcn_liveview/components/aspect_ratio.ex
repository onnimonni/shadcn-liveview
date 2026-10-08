defmodule ShadcnLiveview.Components.AspectRatio do
  @moduledoc false
  use Phoenix.Component

  attr :ratio, :float, default: 1.7777777777777777
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  slot :inner_block, required: false

  def aspect_ratio(assigns) do
    padding = 1.0 / (assigns.ratio || 16.0 / 9.0) * 100.0
    assigns = assign(assigns, :padding, padding)

    ~H"""
    <div
      style={"position:relative;width:100%;padding-bottom:#{@padding}%"}
      data-radix-aspect-ratio-wrapper=""
    >
      <div
        data-slot="aspect-ratio"
        style="position:absolute;top:0;right:0;bottom:0;left:0"
        class={[@class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
