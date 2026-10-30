defmodule ShadcnLiveview.Components.AspectRatio do
  @moduledoc ~S"""
  Displays content within a desired width/height ratio.

  Upstream: https://ui.shadcn.com/docs/components/radix/aspect-ratio

  Components: `aspect_ratio/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.aspect_ratio ratio={16 / 9} class="bg-muted flex items-center justify-center">
    <span>16:9 Aspect Ratio</span>
  </.aspect_ratio>
  ```
  """
  use Phoenix.Component

  attr :ratio, :float, default: 1.7777777777777777

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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
