defmodule ShadcnLiveview.Components.Toggle do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :pressed, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def toggle(assigns) do
    ~H"""
    <button
      type="button"
      aria-pressed={to_string(@pressed)}
      data-state={if @pressed, do: "on", else: "off"}
      data-slot="toggle"
      class={classes(["group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 data-[state=on]:bg-accent data-[state=on]:text-accent-foreground dark:data-[state=on]:bg-accent/50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 size-8", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
