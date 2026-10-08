defmodule ShadcnLiveview.Components.Table do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  slot :inner_block, required: false

  def table(assigns) do
    ~H"""
    <div data-slot="table-container" class="relative w-full overflow-x-auto">
      <table
        data-slot="table"
        class={["w-full caption-bottom text-sm", @class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_header(assigns) do
    ~H"""
    <thead
      data-slot="table-header"
      class={classes(["[&_tr]:border-b", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </thead>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_body(assigns) do
    ~H"""
    <tbody
      data-slot="table-body"
      class={classes(["[&_tr:last-child]:border-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_footer(assigns) do
    ~H"""
    <tfoot
      data-slot="table-footer"
      class={classes(["border-t bg-muted/50 font-medium [&>tr]:last:border-b-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_row(assigns) do
    ~H"""
    <tr
      data-slot="table-row"
      class={
        classes([
          "border-b transition-colors hover:bg-muted/50 has-aria-expanded:bg-muted/50 data-[state=selected]:bg-muted",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </tr>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_head(assigns) do
    ~H"""
    <th
      data-slot="table-head"
      class={
        classes([
          "h-10 px-2 text-left align-middle font-medium whitespace-nowrap text-foreground [&:has([role=checkbox])]:pr-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_cell(assigns) do
    ~H"""
    <td
      data-slot="table-cell"
      class={classes(["p-2 align-middle whitespace-nowrap [&:has([role=checkbox])]:pr-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </td>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def table_caption(assigns) do
    ~H"""
    <caption
      data-slot="table-caption"
      class={classes(["mt-4 text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </caption>
    """
  end
end
