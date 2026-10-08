defmodule ShadcnLiveview.Components.Separator do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :orientation, :string, default: "horizontal"

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def separator(assigns) do
    ~H"""
    <div
      data-slot="separator"
      data-orientation={@orientation}
      role="none"
      class={
        classes([
          "shrink-0 bg-border data-horizontal:h-px data-horizontal:w-full data-vertical:w-px data-vertical:self-stretch",
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
