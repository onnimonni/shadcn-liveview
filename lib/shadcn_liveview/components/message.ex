defmodule ShadcnLiveview.Components.Message do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def message_group(assigns) do
    ~H"""
    <div
      data-slot="message-group"
      class={classes(["flex min-w-0 flex-col gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :align, :string, default: "start"

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def message(assigns) do
    ~H"""
    <div
      data-slot="message"
      data-align={@align}
      class={
        classes([
          "group/message relative flex w-full min-w-0 gap-2 text-sm data-[align=end]:flex-row-reverse",
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

  def message_avatar(assigns) do
    ~H"""
    <div
      data-slot="message-avatar"
      class={
        classes([
          "flex w-fit min-w-8 shrink-0 items-center justify-center self-end overflow-hidden rounded-full bg-muted group-has-data-[slot=message-footer]/message:-translate-y-8",
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

  def message_content(assigns) do
    ~H"""
    <div
      data-slot="message-content"
      class={
        classes([
          "flex w-full min-w-0 flex-col gap-2.5 wrap-break-word group-data-[align=end]/message:*:data-slot:self-end",
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

  def message_header(assigns) do
    ~H"""
    <div
      data-slot="message-header"
      class={
        classes([
          "flex max-w-full min-w-0 items-center px-3 text-xs font-medium text-muted-foreground group-has-data-[variant=ghost]/message:px-0",
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

  def message_footer(assigns) do
    ~H"""
    <div
      data-slot="message-footer"
      class={
        classes([
          "flex max-w-full min-w-0 items-center px-3 text-xs font-medium text-muted-foreground group-has-data-[variant=ghost]/message:px-0 group-data-[align=end]/message:justify-end",
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
