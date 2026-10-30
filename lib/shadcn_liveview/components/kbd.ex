defmodule ShadcnLiveview.Components.Kbd do
  @moduledoc ~S"""
  Displays keyboard input such as shortcuts.

  Upstream: https://ui.shadcn.com/docs/components/radix/kbd

  Components: `kbd/1`, `kbd_group/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.kbd>Ctrl + K</.kbd>
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def kbd(assigns) do
    ~H"""
    <kbd
      data-slot="kbd"
      class={
        classes([
          "pointer-events-none inline-flex h-5 w-fit min-w-5 items-center justify-center gap-1 rounded-sm bg-muted px-1 font-sans text-xs font-medium text-muted-foreground select-none in-data-[slot=tooltip-content]:bg-background/20 in-data-[slot=tooltip-content]:text-background dark:in-data-[slot=tooltip-content]:bg-background/10 [&_svg:not([class*='size-'])]:size-3",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def kbd_group(assigns) do
    ~H"""
    <div
      data-slot="kbd-group"
      class={classes(["inline-flex items-center gap-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
