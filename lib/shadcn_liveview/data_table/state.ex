defmodule ShadcnLiveview.DataTable.State do
  @moduledoc """
  Server-owned state of one `ShadcnLiveview.DataTable`.

  Build it with `ShadcnLiveview.DataTable.new/1`, keep it in an assign and change it only
  through the `ShadcnLiveview.DataTable` functions. Fields:

    * `:id` - DOM id of the table root; every control id derives from it.
    * `:event` - event name every table control pushes (route it to
      `ShadcnLiveview.DataTable.handle_event/2`).
    * Query (URL) state: `:sort` (field or `nil`), `:dir` (`:asc`/`:desc`), `:filter` (text
      search), `:filters` (exact-match facets, field => value), `:page`, `:page_size`.
    * UI state: `:selected` (`MapSet` of row ids as strings; survives paging, sorting and
      filtering), `:hidden` (`MapSet` of hidden column fields), `:open` (DOM id of the open
      column or row-action menu), `:focus` (focus target after `remove_row/2`).
    * Configuration: `:sortable`, `:filterable` (field whitelists, also used to validate URL
      params), `:searchable` (fields the text filter reads; `nil` = every scalar value),
      `:page_sizes`, `:row_key`, `:param_prefix`, `:defaults`.
    * Current page: `:total` (matching rows) and `:page_ids` (row ids on the page).
  """

  @type t :: %__MODULE__{
          id: String.t(),
          event: String.t(),
          sort: String.t() | nil,
          dir: :asc | :desc,
          filter: String.t(),
          filters: %{optional(String.t()) => String.t()},
          page: pos_integer(),
          page_size: pos_integer(),
          page_sizes: [pos_integer()],
          selected: MapSet.t(String.t()),
          hidden: MapSet.t(String.t()),
          open: String.t() | nil,
          focus: %{index: non_neg_integer(), page: pos_integer(), seq: pos_integer()} | nil,
          sortable: [String.t()],
          filterable: [String.t()],
          searchable: [String.t()] | nil,
          row_key: String.t(),
          param_prefix: String.t(),
          total: non_neg_integer(),
          page_ids: [String.t()],
          defaults: map()
        }

  defstruct id: "data-table",
            event: "shadcn:data-table",
            sort: nil,
            dir: :asc,
            filter: "",
            filters: %{},
            page: 1,
            page_size: 10,
            page_sizes: [10, 20, 30, 40, 50],
            selected: MapSet.new(),
            hidden: MapSet.new(),
            open: nil,
            focus: nil,
            sortable: [],
            filterable: [],
            searchable: nil,
            row_key: "id",
            param_prefix: "",
            total: 0,
            page_ids: [],
            defaults: %{}
end
