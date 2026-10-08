defmodule ShadcnLiveview.Components.ButtonGroup do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :orientation, :string, default: "horizontal"

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def button_group(assigns) do
    ~H"""
    <div
      data-slot="button-group"
      role="group"
      class={classes([button_group_classes(@orientation), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @button_group_styles %{
    "horizontal" =>
      "group/button-group flex w-fit items-stretch *:focus-visible:relative *:focus-visible:z-10 has-[>[data-slot=button-group]]:gap-2 has-[select[aria-hidden=true]:last-child]:[&>[data-slot=select-trigger]:last-of-type]:rounded-r-lg [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1 [&>*:not(:first-child)]:rounded-l-none [&>*:not(:first-child)]:border-l-0 [&>*:not(:last-child)]:rounded-r-none [&>[data-slot]:not(:has(~[data-slot]))]:rounded-r-lg!",
    "vertical" =>
      "group/button-group flex w-fit items-stretch *:focus-visible:relative *:focus-visible:z-10 has-[>[data-slot=button-group]]:gap-2 has-[select[aria-hidden=true]:last-child]:[&>[data-slot=select-trigger]:last-of-type]:rounded-r-lg [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1 flex-col [&>*:not(:first-child)]:rounded-t-none [&>*:not(:first-child)]:border-t-0 [&>*:not(:last-child)]:rounded-b-none [&>[data-slot]:not(:has(~[data-slot]))]:rounded-b-lg!"
  }

  defp button_group_classes(orientation) do
    Map.get(
      @button_group_styles,
      orientation || "horizontal",
      "group/button-group flex w-fit items-stretch *:focus-visible:relative *:focus-visible:z-10 has-[>[data-slot=button-group]]:gap-2 has-[select[aria-hidden=true]:last-child]:[&>[data-slot=select-trigger]:last-of-type]:rounded-r-lg [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1 [&>*:not(:first-child)]:rounded-l-none [&>*:not(:first-child)]:border-l-0 [&>*:not(:last-child)]:rounded-r-none [&>[data-slot]:not(:has(~[data-slot]))]:rounded-r-lg!"
    )
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def button_group_text(assigns) do
    ~H"""
    <div
      data-slot="button-group-text"
      class={
        classes([
          "flex items-center gap-2 rounded-lg border bg-muted px-2.5 text-sm font-medium [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4",
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

  def button_group_separator(assigns) do
    ~H"""
    <div
      data-slot="button-group-separator"
      class={
        classes([
          "relative self-stretch bg-input data-horizontal:mx-px data-horizontal:w-auto data-vertical:my-px data-vertical:h-auto",
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
