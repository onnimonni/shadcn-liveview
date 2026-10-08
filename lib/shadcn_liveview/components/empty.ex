defmodule ShadcnLiveview.Components.Empty do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty(assigns) do
    ~H"""
    <div
      data-slot="empty"
      class={
        classes([
          "flex w-full min-w-0 flex-1 flex-col items-center justify-center gap-4 rounded-xl border-dashed p-6 text-center text-balance",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty_header(assigns) do
    ~H"""
    <div
      data-slot="empty-header"
      class={classes(["flex max-w-sm flex-col items-center gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :variant, :string, default: "default"

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty_media(assigns) do
    ~H"""
    <div
      data-slot="empty-icon"
      data-variant={@variant}
      class={classes([empty_media_classes(@variant), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @empty_media_styles %{
    "default" =>
      "mb-2 flex shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-transparent",
    "icon" =>
      "mb-2 [&_svg]:pointer-events-none [&_svg]:shrink-0 flex size-8 shrink-0 items-center justify-center rounded-lg bg-muted text-foreground [&_svg:not([class*='size-'])]:size-4"
  }

  defp empty_media_classes(variant) do
    Map.get(
      @empty_media_styles,
      variant || "default",
      "mb-2 flex shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-transparent"
    )
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty_title(assigns) do
    ~H"""
    <div
      data-slot="empty-title"
      class={classes(["cn-font-heading text-sm font-medium tracking-tight", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty_description(assigns) do
    ~H"""
    <div
      data-slot="empty-description"
      class={
        classes([
          "text-sm/relaxed text-muted-foreground [&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def empty_content(assigns) do
    ~H"""
    <div
      data-slot="empty-content"
      class={
        classes([
          "flex w-full max-w-sm min-w-0 flex-col items-center gap-2.5 text-sm text-balance",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
