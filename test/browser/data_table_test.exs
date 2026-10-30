defmodule ShadcnLiveview.DataTableBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  @search "location.search"

  setup %{conn: conn} do
    {:ok, conn: conn |> visit("/data-table-preview") |> connected()}
  end

  defp sort_button(table, field), do: "##{table} th button[phx-value-sort=#{field}]"
  defp head(table, field), do: "##{table} th:has(button[phx-value-sort=#{field}])"
  defp first_title(table), do: "##{table}-rows tr:first-child td:nth-child(2)"
  defp back(conn), do: tap(conn, &value(&1, "history.back()"))
  defp search_is(conn, query), do: assert_js(conn, "#{@search} === #{Jason.encode!(query)}")

  test "sorting, search (replace), paging and page size live in the URL and Back", %{conn: conn} do
    conn
    |> assert_attribute(head("tasks", "title"), "aria-sort", "none")
    |> click(sort_button("tasks", "title"))
    |> assert_attribute(head("tasks", "title"), "aria-sort", "ascending")
    |> search_is("?sort=title")
    |> click(sort_button("tasks", "title"))
    |> assert_attribute(head("tasks", "title"), "aria-sort", "descending")
    |> assert_text(first_title("tasks"), "Task 32")
    |> search_is("?dir=desc&sort=title")
    # Each search keystroke replaces the current history entry instead of pushing one.
    |> fill("#tasks-q", "Task 1")
    |> search_is("?dir=desc&q=Task+1&sort=title")
    |> fill("#tasks-q", "Task 2")
    |> search_is("?dir=desc&q=Task+2&sort=title")
    |> assert_text(first_title("tasks"), "Task 29")
    |> assert_text("#tasks-page", "Page 1 of 1")
    # A focused input keeps its typed value across patches; leave it like a user reaching for Back.
    |> blur("#tasks-q")
    |> back()
    |> search_is("?sort=title")
    |> assert_attribute(head("tasks", "title"), "aria-sort", "ascending")
    |> assert_value("#tasks-q", "")
    |> assert_text(first_title("tasks"), "Task 01")
    # Paging pushes entries, so Back steps through them.
    |> assert_disabled("#tasks-pagination button[aria-label='Go to previous page']")
    |> click("#tasks-pagination button[aria-label='Go to next page']")
    |> assert_text("#tasks-page", "Page 2 of 4")
    |> assert_text(first_title("tasks"), "Task 11")
    |> click("#tasks-pagination button[aria-label='Go to last page']")
    |> assert_text("#tasks-page", "Page 4 of 4")
    |> assert_disabled("#tasks-pagination button[aria-label='Go to next page']")
    |> assert_count("#tasks-rows tr", 2)
    |> back()
    |> assert_text("#tasks-page", "Page 2 of 4")
    |> select_values("#tasks-page-size", "20")
    |> search_is("?page_size=20&sort=title")
    |> assert_text("#tasks-page", "Page 1 of 2")
    |> assert_count("#tasks-rows tr", 20)
    # Facet filter inside the search form.
    |> select_values("#tasks-search select[name=status]", "done")
    |> assert_count("#tasks-rows tr", 11)
    |> search_is("?page_size=20&sort=title&status=done")
  end

  test "selection survives paging and select-all is per page with an indeterminate state", %{
    conn: conn
  } do
    conn
    |> click(within("#tasks", role("checkbox", "Select Task 01")))
    |> assert_attribute("#tasks-select-all", "aria-checked", "mixed")
    |> assert_attribute("#tasks-row-1", "data-state", "selected")
    |> assert_contains("#tasks-selection", "1 of 32 row(s) selected.")
    |> click("#tasks-pagination button[aria-label='Go to next page']")
    |> assert_text("#tasks-page", "Page 2 of 4")
    |> assert_attribute("#tasks-select-all", "aria-checked", "false")
    |> click("#tasks-select-all")
    |> assert_attribute("#tasks-select-all", "aria-checked", "true")
    |> assert_attribute("#tasks-row-20-select", "aria-checked", "true")
    |> assert_contains("#tasks-selection", "11 of 32 row(s) selected.")
    |> click("#tasks-pagination button[aria-label='Go to previous page']")
    |> assert_text("#tasks-page", "Page 1 of 4")
    |> assert_attribute("#tasks-row-1-select", "aria-checked", "true")
    |> assert_attribute("#tasks-select-all", "aria-checked", "mixed")
    |> click("#tasks-select-all")
    |> assert_attribute("#tasks-select-all", "aria-checked", "true")
    |> assert_contains("#tasks-selection", "20 of 32 row(s) selected.")
  end

  test "column visibility toggles from the keyboard", %{conn: conn} do
    conn
    |> assert_count("#tasks thead th", 6)
    |> focus("#tasks-columns-trigger")
    |> key("Enter")
    |> assert_visible(role("menuitemcheckbox", "Status"))
    |> assert_focused(role("menuitemcheckbox", "Status"))
    |> key("ArrowDown")
    |> assert_focused(role("menuitemcheckbox", "Owner"))
    |> key("Enter")
    |> assert_count("#tasks thead th", 5)
    |> assert_hidden(role("menu"))
    |> assert_focused("#tasks-columns-trigger")
    |> assert_js(
      "![...document.querySelectorAll('#tasks thead th')].some(th => th.textContent.includes('Owner'))"
    )
    |> key("Enter")
    |> assert_attribute(role("menuitemcheckbox", "Owner"), "aria-checked", "false")
    |> key("ArrowDown")
    |> assert_focused(role("menuitemcheckbox", "Owner"))
    |> key(" ")
    |> assert_count("#tasks thead th", 6)
  end

  test "row action menu: keyboard delete moves focus to the next row's trigger", %{conn: conn} do
    conn
    |> focus(within("#tasks", role("button", "Open menu for Task 02")))
    |> key("Enter")
    |> assert_focused(role("menuitem", "Edit"))
    |> key("Enter")
    |> assert_text("#tasks-last-action", "edit 2")
    |> assert_focused("#tasks-row-2-actions-trigger")
    |> key("Enter")
    |> assert_focused(role("menuitem", "Edit"))
    |> key("End")
    |> assert_focused(role("menuitem", "Delete"))
    |> key("Enter")
    |> assert_text("#tasks-last-action", "delete 2")
    |> assert_count("#tasks-row-2", 0)
    |> assert_focused("#tasks-row-3-actions-trigger")
    |> assert_contains("#tasks-selection", "of 31 row(s)")
    # Deleting the page's last row lands on the new last row.
    |> click("#tasks-pagination button[aria-label='Go to last page']")
    |> assert_text("#tasks-page", "Page 4 of 4")
    |> click(within("#tasks", role("button", "Open menu for Task 32")))
    |> click(role("menuitem", "Delete"))
    |> assert_text("#tasks-last-action", "delete 32")
    |> assert_focused("#tasks-row-31-actions-trigger")
  end

  test "a table inside a LiveComponent routes every control with phx-target", %{conn: conn} do
    conn
    |> click(sort_button("archive", "points"))
    |> assert_attribute(head("archive", "points"), "aria-sort", "ascending")
    # Not URL-backed: the component owns its query state.
    |> search_is("")
    |> fill("#archive-q", "Task 3")
    |> assert_count("#archive-rows tr", 3)
    |> fill("#archive-q", "")
    |> click("#archive-row-13-select")
    |> assert_attribute("#archive-select-all", "aria-checked", "mixed")
    |> assert_contains("#archive-selection", "1 of 32 row(s) selected.")
    |> click("#archive-pagination button[aria-label='Go to next page']")
    |> assert_text("#archive-page", "Page 2 of 4")
    |> click("#archive-columns-trigger")
    |> click(role("menuitemcheckbox", "Points"))
    |> assert_count("#archive thead th", 3)
    |> click("#archive-rows tr:first-child button[aria-haspopup=menu]")
    |> click(role("menuitem", "Delete"))
    |> assert_count("#archive-rows tr", 10)
    |> assert_focused("#archive-rows tr:first-child button[aria-haspopup=menu]")
    # The parent table never saw these events.
    |> assert_contains("#tasks-selection", "0 of 32 row(s) selected.")
    |> assert_count("#tasks thead th", 6)
  end
end
