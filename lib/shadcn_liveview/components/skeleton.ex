defmodule ShadcnLiveview.Components.Skeleton do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def skeleton(assigns) do
    ~H"""
    <div
      data-slot="skeleton"
      class={classes(["animate-pulse rounded-md bg-muted", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
