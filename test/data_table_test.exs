defmodule ShadcnLiveview.DataTableTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe
  alias ShadcnLiveview.DataTable

  @rows for n <- 1..25,
            do: %{
              id: n,
              title: "Task #{String.pad_leading(to_string(n), 2, "0")}",
              status: if(rem(n, 3) == 0, do: "done", else: "todo"),
              due: Date.add(~D[2026-01-01], 25 - n),
              points: if(n == 7, do: nil, else: rem(n * 7, 11))
            }

  defp new_table(opts \\ []) do
    DataTable.new(
      Keyword.merge(
        [id: "tasks", sortable: ~w(title status due points)a, filterable: [:status]],
        opts
      )
    )
  end

  defp ids(rows), do: Enum.map(rows, & &1.id)

  describe "params" do
    test "round-trip through to_params/from_params and omit defaults" do
      state = %{
        new_table(sort: :title)
        | sort: "due",
          dir: :desc,
          filter: "task 1",
          filters: %{"status" => "done"},
          page: 3,
          page_size: 20
      }

      params = DataTable.to_params(state)

      assert params == %{
               "q" => "task 1",
               "sort" => "due",
               "dir" => "desc",
               "page" => "3",
               "page_size" => "20",
               "status" => "done"
             }

      restored = DataTable.from_params(params, new_table(sort: :title))

      assert Map.take(restored, ~w(sort dir filter filters page page_size)a) ==
               Map.take(state, ~w(sort dir filter filters page page_size)a)

      assert DataTable.to_params(new_table(sort: :title)) == %{}
      # Explicitly unsorted while the default sorts: kept as an empty sort param.
      assert DataTable.to_params(%{new_table(sort: :title) | sort: nil}) == %{"sort" => ""}
      assert DataTable.from_params(%{"sort" => ""}, new_table(sort: :title)).sort == nil
    end

    test "invalid params fall back to the defaults and keep UI state" do
      state = %{new_table(sort: :title, page_size: 20) | selected: MapSet.new(["3"]), open: "x"}

      parsed =
        DataTable.from_params(
          %{
            "sort" => "secret_column",
            "dir" => "sideways",
            "page" => "-2",
            "page_size" => "7",
            "q" => ["not", "text"],
            "status" => ""
          },
          state
        )

      assert parsed.sort == "title"
      assert parsed.dir == :asc
      assert parsed.page == 1
      assert parsed.page_size == 20
      assert parsed.filter == ""
      assert parsed.filters == %{}
      assert parsed.selected == MapSet.new(["3"])
      assert parsed.open == "x"
      assert DataTable.from_params(%{"page" => "2abc"}, state).page == 1
    end

    test "param_prefix namespaces the URL keys" do
      state = %{new_table(param_prefix: "t_") | page: 2, filter: "x"}
      assert DataTable.to_params(state) == %{"t_page" => "2", "t_q" => "x"}
      assert DataTable.from_params(%{"t_page" => "2", "page" => "5"}, state).page == 2
    end

    test "new/1 rejects a default sort outside the whitelist" do
      assert_raise ArgumentError, ~r/not in :sortable/, fn -> new_table(sort: :owner) end
    end
  end

  describe "apply/2" do
    test "paginates with page boundaries and clamps past the last page" do
      {rows, state} = DataTable.apply(new_table(), @rows)
      assert ids(rows) == Enum.to_list(1..10)
      assert {state.total, DataTable.page_count(state)} == {25, 3}
      assert state.page_ids == Enum.map(1..10, &to_string/1)

      {rows, state} = DataTable.apply(%{state | page: 3}, @rows)
      assert ids(rows) == [21, 22, 23, 24, 25]

      {rows, state} = DataTable.apply(%{state | page: 9}, @rows)
      assert state.page == 3
      assert ids(rows) == [21, 22, 23, 24, 25]

      {[], empty} = DataTable.apply(%{state | filter: "nothing matches"}, @rows)

      assert {empty.page, empty.total, DataTable.page_count(empty), empty.page_ids} ==
               {1, 0, 1, []}
    end

    test "filters by text (case-insensitive) and facets" do
      {rows, state} = DataTable.apply(%{new_table() | filter: "  TASK 1"}, @rows)
      assert ids(rows) == Enum.to_list(10..19)
      assert state.total == 10

      {rows, _state} = DataTable.apply(%{new_table() | filters: %{"status" => "done"}}, @rows)
      assert ids(rows) == [3, 6, 9, 12, 15, 18, 21, 24]

      {rows, _state} =
        DataTable.apply(%{new_table(searchable: [:status]) | filter: "task"}, @rows)

      assert rows == []
    end

    test "sorts strings, dates and numbers in both directions with nil last" do
      {rows, _} = DataTable.apply(%{new_table() | sort: "due", page_size: 30}, @rows)
      assert hd(rows).id == 25

      {rows, _} =
        DataTable.apply(%{new_table() | sort: "points", dir: :desc, page_size: 30}, @rows)

      assert Enum.map(rows, & &1.points) |> Enum.take(2) == [10, 10]
      assert List.last(rows).id == 7

      {rows, _} = DataTable.apply(%{new_table() | sort: "title", dir: :desc}, @rows)
      assert hd(rows).id == 25
    end

    test "reads string-keyed rows and structs" do
      rows = [%{"id" => "b", "name" => "Beta"}, %{"id" => "a", "name" => "alpha"}]
      {sorted, state} = DataTable.apply(%{new_table(sortable: ["name"]) | sort: "name"}, rows)
      assert Enum.map(sorted, & &1["id"]) == ["a", "b"]
      assert state.page_ids == ["a", "b"]
      assert DataTable.value(%URI{host: "x"}, "host") == "x"
      assert DataTable.value(%{}, "no_such_atom_#{System.unique_integer()}") == nil
    end

    test "database helpers expose offset, order_by and clamped totals" do
      state = DataTable.put_total(%{new_table() | page: 4, sort: "title", dir: :desc}, 25)
      assert state.page == 3
      assert DataTable.offset(state) == 20
      assert DataTable.order_by(state) == [desc: :title]
      assert DataTable.order_by(new_table()) == []
      assert DataTable.put_rows(state, [%{id: 21}]).page_ids == ["21"]
    end
  end

  describe "handle_event/2" do
    setup do
      {_rows, state} = DataTable.apply(new_table(), @rows)
      %{state: state}
    end

    test "sort cycles asc, desc, off and resets the page", %{state: state} do
      state = %{state | page: 2}

      assert {:query, asc, []} =
               DataTable.handle_event(%{"sort" => "title", "value" => ""}, state)

      assert {asc.sort, asc.dir, asc.page} == {"title", :asc, 1}
      assert {:query, desc, []} = DataTable.handle_event(%{"sort" => "title"}, asc)
      assert {desc.sort, desc.dir} == {"title", :desc}
      assert {:query, off, []} = DataTable.handle_event(%{"sort" => "title"}, desc)
      assert off.sort == nil
      assert {:ok, ^state} = DataTable.handle_event(%{"sort" => "secret"}, state)
    end

    test "page, page size and search", %{state: state} do
      assert {:query, %{page: 3}, []} = DataTable.handle_event(%{"page" => "3"}, state)
      assert {:query, %{page: 3}, []} = DataTable.handle_event(%{"page" => "99"}, state)
      assert {:ok, ^state} = DataTable.handle_event(%{"page" => "zero"}, state)

      assert {:query, %{page_size: 20, page: 1}, []} =
               DataTable.handle_event(%{"page_size" => "20"}, %{state | page: 2})

      assert {:ok, ^state} = DataTable.handle_event(%{"page_size" => "13"}, state)

      assert {:query, searched, [replace: true]} =
               DataTable.handle_event(
                 %{"q" => "task", "status" => "done", "_target" => ["q"]},
                 %{state | page: 3}
               )

      assert {searched.filter, searched.filters, searched.page} ==
               {"task", %{"status" => "done"}, 1}
    end

    test "selection survives paging; select-all covers the page", %{state: state} do
      {:ok, state} =
        DataTable.handle_event(%{"id" => "tasks-row-2-select", "value" => true}, state)

      assert state.selected == MapSet.new(["2"])

      {_rows, page2} = DataTable.apply(%{state | page: 2}, @rows)
      {:ok, page2} = DataTable.handle_event(%{"id" => "tasks-select-all", "value" => true}, page2)
      assert MapSet.size(page2.selected) == 11

      {_rows, page1} = DataTable.apply(%{page2 | page: 1}, @rows)
      assert "2" in page1.selected

      {:ok, cleared} =
        DataTable.handle_event(%{"id" => "tasks-select-all", "value" => false}, page1)

      assert MapSet.size(cleared.selected) == 10
      refute "2" in cleared.selected

      {:ok, off} =
        DataTable.handle_event(%{"id" => "tasks-row-11-select", "value" => false}, cleared)

      refute "11" in off.selected
    end

    test "column menu toggles hidden columns; row menus open and return actions", %{
      state: state
    } do
      {:ok, open} = DataTable.handle_event(%{"id" => "tasks-columns", "action" => "open"}, state)
      assert open.open == "tasks-columns"

      {:ok, hidden} =
        DataTable.handle_event(
          %{
            "id" => "tasks-columns",
            "action" => "select",
            "value" => "status",
            "checked" => false,
            "role" => "menuitemcheckbox"
          },
          open
        )

      assert hidden.hidden == MapSet.new(["status"])

      {:ok, closed} =
        DataTable.handle_event(%{"id" => "tasks-columns", "action" => "close"}, hidden)

      assert closed.open == nil

      {:ok, shown} =
        DataTable.handle_event(
          %{
            "id" => "tasks-columns",
            "action" => "select",
            "value" => "status",
            "checked" => true
          },
          closed
        )

      assert shown.hidden == MapSet.new()

      menu = "tasks-row-4-actions"
      {:ok, open} = DataTable.handle_event(%{"id" => menu, "action" => "open"}, state)
      assert open.open == menu

      assert {:action, "delete", "4", %{open: nil}} =
               DataTable.handle_event(
                 %{"id" => menu, "action" => "select", "value" => "delete"},
                 open
               )

      assert {:ok, ^state} =
               DataTable.handle_event(%{"id" => "other-menu", "action" => "open"}, state)
    end

    test "remove_row/2 forgets the row and targets its successor", %{state: state} do
      state = %{state | selected: MapSet.new(["3", "4"])}
      removed = DataTable.remove_row(state, 3)
      assert removed.selected == MapSet.new(["4"])
      assert removed.focus == %{index: 2, page: 1, seq: 1}
      assert DataTable.remove_row(removed, 4).focus == %{index: 2, page: 1, seq: 2}
    end
  end

  describe "rendering" do
    defp render(assigns) do
      ~H"""
      <.data_table_search state={@table} placeholder="Filter tasks" />
      <.data_table_view_options state={@table} columns={[{"status", "Status"}, "due"]} />
      <.data_table state={@table} rows={@rows} selectable row_label="title" target={@target}>
        <:col :let={task} field="title" label="Title" class="font-medium">{task.title}!</:col>
        <:col field="status" label="Status" />
        <:col field="due" label="Due" />
        <:row_actions class="w-32">
          <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
        </:row_actions>
      </.data_table>
      <.data_table_pagination state={@table} selectable target={@target} />
      """
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_fragment!()
    end

    defp doc(state, opts \\ []) do
      {rows, state} = DataTable.apply(state, @rows)
      render(%{table: state, rows: Keyword.get(opts, :rows, rows), target: opts[:target]})
    end

    test "headers expose aria-sort and sort buttons only for sortable fields" do
      document = doc(%{new_table(sortable: [:title, :due]) | sort: "due", dir: :desc})
      heads = Floki.find(document, "thead th[scope=col]")
      sorts = Enum.map(heads, &(Floki.attribute(&1, "aria-sort") |> List.first()))
      assert sorts == [nil, "none", nil, "descending", nil]

      assert Floki.attribute(document, "th button[phx-value-sort]", "phx-value-sort") ==
               ~w(title due)

      assert Floki.text(Floki.find(document, "tbody tr:first-child td.font-medium")) =~ "Task 01!"
      assert Floki.text(Floki.find(document, "#tasks-row-1 td")) =~ "todo"
    end

    test "select-all reflects none, some (indeterminate) and all rows of the page" do
      state = new_table()
      assert Floki.attribute(doc(state), "#tasks-select-all", "aria-checked") == ["false"]
      some = %{state | selected: MapSet.new(["1", "30"])}
      assert Floki.attribute(doc(some), "#tasks-select-all", "aria-checked") == ["mixed"]
      assert Floki.attribute(doc(some), "#tasks-row-1", "data-state") == ["selected"]
      assert Floki.attribute(doc(some), "#tasks-row-1-select", "aria-label") == ["Select Task 01"]
      all = %{state | selected: MapSet.new(Enum.map(1..10, &to_string/1))}
      assert Floki.attribute(doc(all), "#tasks-select-all", "aria-checked") == ["true"]
      text = Floki.text(Floki.find(doc(all), "#tasks-selection"))
      assert text =~ "10 of 25 row(s) selected."
    end

    test "pagination disables the boundary buttons and shows the page size" do
      first = doc(new_table())
      disabled = &Floki.attribute(&1, "button[aria-label='Go to #{&2} page']", "disabled")
      assert disabled.(first, "first") == ["disabled"]
      assert disabled.(first, "previous") == ["disabled"]
      assert disabled.(first, "next") == []

      assert Floki.attribute(first, "button[aria-label='Go to last page']", "phx-value-page") == [
               "3"
             ]

      assert Floki.text(Floki.find(first, "#tasks-page")) =~ "Page 1 of 3"
      assert Floki.attribute(first, "#tasks-page-size option[selected]", "value") == ["10"]

      last = doc(%{new_table() | page: 3})
      assert disabled.(last, "next") == ["disabled"]
      assert disabled.(last, "last") == ["disabled"]
      assert disabled.(last, "previous") == []
    end

    test "hidden columns, view options and the empty state" do
      state = %{new_table() | hidden: MapSet.new(["status"]), filter: "nothing"}
      document = doc(state)
      assert Floki.text(Floki.find(document, "thead")) =~ "Due"
      refute Floki.text(Floki.find(document, "thead")) =~ "Status"
      assert Floki.text(Floki.find(document, "#tasks-empty td")) =~ "No results."
      assert Floki.attribute(document, "#tasks-empty td", "colspan") == ["4"]
      assert Floki.attribute(document, "#tasks-select-all", "disabled") == ["disabled"]

      open = doc(%{state | open: "tasks-columns"})
      items = Floki.find(open, "[role=menuitemcheckbox]")
      assert Enum.map(items, &Floki.attribute(&1, "aria-checked")) == [["false"], ["true"]]
      assert Floki.text(items) =~ "due"
    end

    test "row menus, targets and the focus target after a delete" do
      {_rows, state} = DataTable.apply(new_table(), @rows)
      state = DataTable.remove_row(%{state | open: "tasks-row-2-actions"}, "2")
      rest = Enum.reject(@rows, &(&1.id == 2))
      {rows, state} = DataTable.apply(state, rest)
      document = render(%{table: state, rows: rows, target: "#owner"})

      assert Floki.attribute(document, "#tasks", "phx-target") == ["#owner"]

      assert Floki.attribute(document, "#tasks-row-3-actions-trigger", "aria-label") ==
               ["Open menu for Task 03"]

      assert [focus] = Floki.attribute(document, "#tasks-focus-1", "phx-mounted")
      assert focus =~ ~s(tasks-row-3-actions-trigger)

      assert Floki.attribute(document, "#tasks-pagination button[phx-value-page]", "phx-target")
             |> Enum.uniq() == ["#owner"]

      open = render(%{table: %{state | open: "tasks-row-3-actions"}, rows: rows, target: nil})
      assert Floki.text(Floki.find(open, "[role=menuitem]")) =~ "Delete"
      assert Floki.find(open, "[role=menu].w-32") != []
    end
  end
end
