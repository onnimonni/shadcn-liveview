defmodule ShadcnLiveview.Components.Accordion do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :orientation, :string, default: "vertical"
  attr :type, :string, default: "single"
  attr :default_value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion(assigns) do
    ~H"""
    <div
      data-slot="accordion"
      data-orientation={@orientation}
      class={classes(["flex w-full flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_item(assigns) do
    ~H"""
    <div
      data-slot="accordion-item"
      data-state="open"
      data-orientation="vertical"
      class={classes(["not-last:border-b", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_trigger(assigns) do
    ~H"""
    <h3 class="flex" data-orientation="vertical" data-state="open">
      <button
        type="button"
        data-slot="accordion-trigger"
        data-orientation="vertical"
        data-state="open"
        aria-expanded="true"
        aria-disabled="true"
        data-radix-collection-item=""
        id="radix-id"
        aria-controls="radix-id"
        class={["group/accordion-trigger relative flex flex-1 items-start justify-between rounded-lg border border-transparent py-2.5 text-left text-sm font-medium transition-all outline-none hover:underline focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:after:border-ring disabled:pointer-events-none disabled:opacity-50 **:data-[slot=accordion-trigger-icon]:ml-auto **:data-[slot=accordion-trigger-icon]:size-4 **:data-[slot=accordion-trigger-icon]:text-muted-foreground", @class]}
        {@rest}
      >
        {render_slot(@inner_block)}
        <ShadcnLiveview.Components.Icon.icon name="chevron-down" data-slot="accordion-trigger-icon" class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:hidden" />
        <ShadcnLiveview.Components.Icon.icon name="chevron-up" data-slot="accordion-trigger-icon" class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:inline hidden" />
      </button>
    </h3>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def accordion_content(assigns) do
    ~H"""
    <div
      data-slot="accordion-content"
      data-state="open"
      data-orientation="vertical"
      role="region"
      id="radix-id"
      aria-labelledby="radix-id"
      style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"
      class={classes(["overflow-hidden text-sm data-closed:animate-accordion-up data-open:animate-accordion-down", @class])}
      {@rest}
    >
      <div class="h-(--radix-accordion-content-height) pt-0 pb-2.5 [&_a]:underline [&_a]:underline-offset-3 [&_a]:hover:text-foreground [&_p:not(:last-child)]:mb-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
