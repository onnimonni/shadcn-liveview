defmodule ShadcnLiveview.Components.Slider do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :default_value, :list, default: [50]
  attr :max, :integer, default: 100
  attr :step, :integer, default: 1
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def slider(assigns) do
    ~H"""
    <span
      dir="ltr"
      data-orientation="horizontal"
      aria-disabled="false"
      data-slot="slider"
      style="--radix-slider-thumb-transform:translateX(-50%)"
      class={classes(["relative flex touch-none items-center select-none data-disabled:opacity-50 data-vertical:h-full data-vertical:min-h-40 data-vertical:w-auto data-vertical:flex-col", @class])}
      {@rest}
    >
      <span
        data-slot="slider-track"
        data-orientation="horizontal"
        class="relative grow overflow-hidden rounded-full bg-muted data-horizontal:h-1 data-horizontal:w-full data-vertical:h-full data-vertical:w-1"
      >
        <span
          data-slot="slider-range"
          data-orientation="horizontal"
          style="left:0%;right:50%"
          class="absolute bg-primary select-none data-horizontal:h-full data-vertical:w-full"
        />
      </span>
      <span style="transform:var(--radix-slider-thumb-transform);position:absolute;left:50%">
        <span
          data-slot="slider-thumb"
          data-orientation="horizontal"
          role="slider"
          aria-valuenow="50"
          aria-valuemin="0"
          aria-valuemax="100"
          tabindex="0"
          class="relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50"
        />
      </span>
    </span>
    """
  end
end
