defmodule ShadcnLiveview.Components.Dialog do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_trigger(assigns) do
    ~H"""
    <button
      data-slot="dialog-trigger"
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

  def dialog_portal(assigns) do
    ~H"""
    <div
      data-slot="dialog-portal"
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

  def dialog_close(assigns) do
    ~H"""
    <button
      data-slot="dialog-close"
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

  def dialog_overlay(assigns) do
    ~H"""
    <div
      data-slot="dialog-overlay"
      class={classes(["fixed inset-0 isolate z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="dialog-overlay"
      class="fixed inset-0 isolate z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"
      style="pointer-events:auto"
    />
    <div
      role="dialog"
      data-state="open"
      data-slot="dialog-content"
      tabindex="-1"
      class={classes(["fixed top-1/2 left-1/2 z-50 grid w-full max-w-[calc(100%-2rem)] -translate-x-1/2 -translate-y-1/2 gap-4 rounded-xl bg-popover p-4 text-sm text-popover-foreground ring-1 ring-foreground/10 duration-100 outline-none sm:max-w-sm data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
      <button type="button" data-slot="dialog-close" class="absolute top-2 right-2 inline-flex size-7 items-center justify-center rounded-[min(var(--radius-md),12px)] text-muted-foreground transition-opacity hover:opacity-100">
        <ShadcnLiveview.Components.Icon.icon name="x" class="size-4" />
        <span class="sr-only">Close</span>
      </button>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_header(assigns) do
    ~H"""
    <div
      data-slot="dialog-header"
      class={classes(["flex flex-col gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_footer(assigns) do
    ~H"""
    <div
      data-slot="dialog-footer"
      class={classes(["-mx-4 -mb-4 flex flex-col-reverse gap-2 rounded-b-xl border-t bg-muted/50 p-4 sm:flex-row sm:justify-end", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_title(assigns) do
    ~H"""
    <h2
      data-slot="dialog-title"
      class={classes(["cn-font-heading text-base leading-none font-medium", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dialog_description(assigns) do
    ~H"""
    <p
      data-slot="dialog-description"
      class={classes(["text-sm text-muted-foreground *:[a]:underline *:[a]:underline-offset-3 *:[a]:hover:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end
end
