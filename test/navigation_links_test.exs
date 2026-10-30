defmodule ShadcnLiveview.NavigationLinksTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "button renders a styled LiveView link only when given a destination" do
    assigns = %{}

    document =
      parse(~H"""
      <.button id="plain" variant="outline" size="sm">Save</.button>
      <.button id="navigate" navigate="/tasks" variant="outline" size="sm">Tasks</.button>
      <.button id="patch" patch="/tasks?page=2" replace>Next</.button>
      <.button id="href" href="/export.csv" target="_blank" download>Export</.button>
      """)

    assert [{"button", _, _}] = Floki.find(document, "#plain")
    assert Floki.attribute(document, "#navigate", "href") == ["/tasks"]
    assert Floki.attribute(document, "#navigate", "data-phx-link") == ["redirect"]
    assert Floki.attribute(document, "#navigate", "data-slot") == ["button"]
    assert Floki.attribute(document, "#navigate", "data-variant") == ["outline"]
    assert Floki.attribute(document, "#navigate", "data-size") == ["sm"]

    assert Floki.attribute(document, "#navigate", "class") ==
             Floki.attribute(document, "#plain", "class")

    assert Floki.attribute(document, "#patch", "data-phx-link") == ["patch"]
    assert Floki.attribute(document, "#patch", "data-phx-link-state") == ["replace"]
    assert [{"a", _, _}] = Floki.find(document, "#href")
    assert Floki.attribute(document, "#href", "href") == ["/export.csv"]
    assert Floki.attribute(document, "#href", "target") == ["_blank"]
    assert Floki.attribute(document, "#href", "data-phx-link") == []
  end

  test "navigation anchors accept navigate and patch while href stays a plain link" do
    assigns = %{}

    document =
      parse(~H"""
      <.breadcrumb_link id="crumb" navigate="/projects">Projects</.breadcrumb_link>
      <.breadcrumb_link id="crumb-href" href="/">Home</.breadcrumb_link>
      <.pagination_link id="page" patch="/tasks?page=2" is_active={true}>2</.pagination_link>
      <.pagination_previous id="previous" patch="/tasks?page=1" />
      <.pagination_next id="next" href="#page-3" />
      <.sidebar_menu_button id="menu" navigate="/settings" is_active={true}>Settings</.sidebar_menu_button>
      <.sidebar_menu_sub_button id="sub" patch="/settings/profile">Profile</.sidebar_menu_sub_button>
      <.navigation_menu_link id="nav" navigate="/docs">Docs</.navigation_menu_link>
      """)

    assert Floki.attribute(document, "#crumb", "data-phx-link") == ["redirect"]
    assert Floki.attribute(document, "#crumb", "data-slot") == ["breadcrumb-link"]
    assert Floki.attribute(document, "#crumb-href", "data-phx-link") == []
    assert Floki.attribute(document, "#page", "data-phx-link") == ["patch"]
    assert Floki.attribute(document, "#page", "aria-current") == ["page"]
    assert Floki.attribute(document, "#page", "data-variant") == ["outline"]
    assert Floki.attribute(document, "#previous", "href") == ["/tasks?page=1"]
    assert Floki.attribute(document, "#previous", "aria-label") == ["Go to previous page"]
    assert Floki.attribute(document, "#next", "href") == ["#page-3"]
    assert Floki.attribute(document, "#next", "data-phx-link") == []
    assert [{"a", _, _}] = Floki.find(document, "#menu")
    assert Floki.attribute(document, "#menu", "data-phx-link") == ["redirect"]
    assert Floki.attribute(document, "#menu", "data-active") == ["true"]
    assert Floki.attribute(document, "#sub", "data-phx-link") == ["patch"]
    assert Floki.attribute(document, "#nav", "data-phx-link") == ["redirect"]
    assert Floki.attribute(document, "#nav", "data-slot") == ["navigation-menu-link"]
  end

  test "pagination keeps the upstream landmark label unless the caller overrides it" do
    assigns = %{}

    document =
      parse(~H"""
      <.pagination id="default-pages" />
      <.pagination id="task-pages" aria-label="Task pages" />
      """)

    assert Floki.attribute(document, "#default-pages", "aria-label") == ["pagination"]
    assert Floki.attribute(document, "#task-pages", "aria-label") == ["Task pages"]
  end

  test "class accepts HEEx lists and table cells accept semantic attributes" do
    assigns = %{highlight: false}

    document =
      parse(~H"""
      <.button id="listed" class={["mt-2", @highlight && "ring-2", nil]}>Go</.button>
      <.table>
        <.table_body>
          <.table_row>
            <.table_head id="head" scope="row" abbr="Inv" headers="h1">INV001</.table_head>
            <.table_cell id="cell" colspan="2" rowspan="1" headers="head">Paid</.table_cell>
          </.table_row>
        </.table_body>
      </.table>
      """)

    [class] = Floki.attribute(document, "#listed", "class")
    assert "mt-2" in String.split(class)
    refute "false" in String.split(class)
    refute "ring-2" in String.split(class)
    assert Floki.attribute(document, "#head", "scope") == ["row"]
    assert Floki.attribute(document, "#head", "abbr") == ["Inv"]
    assert Floki.attribute(document, "#cell", "colspan") == ["2"]
    assert Floki.attribute(document, "#cell", "headers") == ["head"]
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_document!()
  end
end
