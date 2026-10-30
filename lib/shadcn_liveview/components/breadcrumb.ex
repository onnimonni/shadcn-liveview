defmodule ShadcnLiveview.Components.Breadcrumb do
  @moduledoc ~S"""
  Displays the path to the current resource as a hierarchy of links.

  Upstream: https://ui.shadcn.com/docs/components/radix/breadcrumb

  Components: `breadcrumb/1`, `breadcrumb_list/1`, `breadcrumb_item/1`, `breadcrumb_link/1`, `breadcrumb_page/1`, `breadcrumb_separator/1`, `breadcrumb_ellipsis/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.breadcrumb>
    <.breadcrumb_list>
      <.breadcrumb_item>
        <.breadcrumb_link href="/">Home</.breadcrumb_link>
      </.breadcrumb_item>
      <.breadcrumb_separator />
      <.breadcrumb_item>
        <.breadcrumb_page>Components</.breadcrumb_page>
      </.breadcrumb_item>
    </.breadcrumb_list>
  </.breadcrumb>
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

  def breadcrumb(assigns) do
    ~H"""
    <nav data-slot="breadcrumb" aria-label="breadcrumb" class={classes(["", @class])} {@rest}>
      {render_slot(@inner_block)}
    </nav>
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

  def breadcrumb_list(assigns) do
    ~H"""
    <ol
      data-slot="breadcrumb-list"
      class={
        classes([
          "flex flex-wrap items-center gap-1.5 text-sm wrap-break-word text-muted-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </ol>
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

  def breadcrumb_item(assigns) do
    ~H"""
    <li
      data-slot="breadcrumb-item"
      class={classes(["inline-flex items-center gap-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :navigate, :string,
    default: nil,
    doc:
      "LiveView `navigate` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :patch, :string,
    default: nil,
    doc:
      "LiveView `patch` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :replace, :boolean,
    default: false,
    doc: "Replaces the browser history entry for `navigate` and `patch` links."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def breadcrumb_link(assigns) do
    ~H"""
    <.link
      :if={@navigate || @patch}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      data-slot="breadcrumb-link"
      class={classes(["transition-colors hover:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <a
      :if={!(@navigate || @patch)}
      data-slot="breadcrumb-link"
      class={classes(["transition-colors hover:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
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

  def breadcrumb_page(assigns) do
    ~H"""
    <span
      data-slot="breadcrumb-page"
      role="link"
      aria-disabled="true"
      aria-current="page"
      class={classes(["font-normal text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  slot :inner_block, required: false

  def breadcrumb_separator(assigns) do
    ~H"""
    <li
      data-slot="breadcrumb-separator"
      role="presentation"
      aria-hidden="true"
      class={["[&>svg]:size-3.5", @class]}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" class="cn-rtl-flip" />
    </li>
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

  def breadcrumb_ellipsis(assigns) do
    ~H"""
    <span
      data-slot="breadcrumb-ellipsis"
      role="presentation"
      class={classes(["flex size-5 items-center justify-center [&>svg]:size-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
