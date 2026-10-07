defmodule ShadcnLiveview.Components.Collapsible do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :open, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def collapsible(assigns) do
    ~H"""
    <div
      data-slot="collapsible"
      data-state={if @open, do: "open", else: "closed"}
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

  def collapsible_trigger(assigns) do
    ~H"""
    <button
      type="button"
      aria-controls="radix-id"
      aria-expanded="true"
      data-state="open"
      data-slot="collapsible-trigger"
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

  def collapsible_content(assigns) do
    ~H"""
    <div
      id="radix-id"
      data-state="open"
      data-slot="collapsible-content"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
