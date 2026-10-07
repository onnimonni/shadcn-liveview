defmodule ShadcnLiveview.Components.Marker do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def marker(assigns) do
    ~H"""
    <div
      data-slot="marker" data-variant={@variant}
      class={classes([marker_classes(@variant), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp marker_classes(variant) do
    case to_string(variant || "default") do
      "default" -> "group/marker relative flex min-h-4 w-full items-center gap-2 text-left text-sm text-muted-foreground [&_svg:not([class*='size-'])]:size-4 [a]:underline [a]:underline-offset-3 [a]:hover:text-foreground"
      "separator" -> "group/marker relative flex min-h-4 w-full items-center gap-2 text-left text-sm text-muted-foreground [&_svg:not([class*='size-'])]:size-4 [a]:underline [a]:underline-offset-3 [a]:hover:text-foreground before:mr-1 before:h-px before:min-w-0 before:flex-1 before:bg-border after:ml-1 after:h-px after:min-w-0 after:flex-1 after:bg-border"
      "border" -> "group/marker relative flex min-h-4 w-full items-center gap-2 text-left text-sm text-muted-foreground [&_svg:not([class*='size-'])]:size-4 [a]:underline [a]:underline-offset-3 [a]:hover:text-foreground border-b border-border pb-2"
      _ -> "group/marker relative flex min-h-4 w-full items-center gap-2 text-left text-sm text-muted-foreground [&_svg:not([class*='size-'])]:size-4 [a]:underline [a]:underline-offset-3 [a]:hover:text-foreground"
    end
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def marker_icon(assigns) do
    ~H"""
    <span
      data-slot="marker-icon"
      class={classes(["size-4 shrink-0 [&_svg:not([class*='size-'])]:size-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def marker_content(assigns) do
    ~H"""
    <span
      data-slot="marker-content"
      class={classes(["min-w-0 wrap-break-word group-data-[variant=separator]/marker:flex-none group-data-[variant=separator]/marker:text-center *:[a]:underline *:[a]:underline-offset-3 *:[a]:hover:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
