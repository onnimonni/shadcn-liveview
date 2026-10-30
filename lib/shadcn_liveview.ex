defmodule ShadcnLiveview do
  @moduledoc """
  Phoenix LiveView function components converted from shadcn/ui's
  [Radix Nova registry](https://ui.shadcn.com/r/styles/radix-nova/registry.json).
  Interactive behavior uses Phoenix colocated hooks; no React runtime is involved.

  ## Installation

  In a Phoenix 1.8 app, run the bundled Igniter installer (the `igniter_new`
  archive provides `mix igniter.install`):

  ```sh
  mix igniter.install shadcn_liveview
  ```

  It wires the assets and hooks below, removes daisyUI, adds
  `use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]` to
  `html_helpers` and replaces the daisyUI `CoreComponents`/`Layouts` with
  shadcn-styled versions that keep Phoenix's API, so `phx.gen.*` output keeps
  working. See `Mix.Tasks.ShadcnLiveview.Install` for flags.

  For a manual setup add `:shadcn_liveview` to your `mix.exs` dependencies and run
  `mix deps.get`.
  The package ships `priv/static/shadcn.tailwind.css` (Tailwind v4 source entry),
  prebuilt `priv/static/shadcn.css` and `priv/static/shadcn-hooks.js`; consumers need
  neither React nor this project's conversion tooling. Agent rules ship in
  `usage-rules.md` and `usage-rules/` (component index: `usage-rules/components.md`).

  ## Assets

  In a stock `phx.new` app, import the Tailwind entry right after Tailwind in
  `assets/css/app.css` (and delete phx.new's `@custom-variant dark` line):

  ```css
  @import "tailwindcss" source(none);
  @import "shadcn_liveview/priv/static/shadcn.tailwind.css";
  ```

  and merge the hook registry into your LiveSocket in `assets/js/app.js`:

  ```js
  import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"

  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: {...colocatedHooks, ...shadcnHooks},
    // ...your existing options
  })
  ```

  Path dependencies also need `Path.join(Mix.Project.build_path(), "lib")` in the
  esbuild and tailwind `NODE_PATH`. Apps without Tailwind instead serve the prebuilt
  files with
  `plug Plug.Static, at: "/shadcn", from: :shadcn_liveview, only: ~w(shadcn.css shadcn-hooks.js)`.
  Never import both stylesheets.
  Dark tokens and `dark:` utilities apply inside either a `.dark` element or
  Phoenix 1.8's `[data-theme=dark]`, so the stock theme toggle needs no bridge.

  ## Importing components

  `use ShadcnLiveview` imports the function components (arity 1) of every family
  plus `ShadcnLiveview.Form.form_field/1` and the `ShadcnLiveview.DataTable`
  components (`data_table/1`, `data_table_search/1`, `data_table_view_options/1`,
  `data_table_pagination/1`); module helpers such as `Calendar.shift_month/2` or
  `DataTable.apply/2` are not imported. Pass `only:` or `except:` with
  `name: arity` pairs to filter across all families, as with `Kernel.import/2`.

  Phoenix 1.8 `CoreComponents` also defines `button/1`, `input/1`, `icon/1` and
  `table/1`. The installer keeps those four in CoreComponents (rewritten over this
  library, with the API `mix phx.gen.live`/`phx.gen.html` templates call) and
  imports everything else:

  ```elixir
  import MyAppWeb.CoreComponents
  use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]
  ```

  Without generated templates you can instead exclude the four from CoreComponents
  (`import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1, icon: 1]`
  plus `use ShadcnLiveview`); this library's `icon/1` renders `hero-*` names like
  CoreComponents and every other name from its Lucide set.

  ## State, forms and events

  Interactive components are server-controlled: give each a stable `id`, keep
  state such as `open` or `value` in assigns, and handle the `on_*` event that
  each module documents. Bind controls to Phoenix `to_form/2` fields with
  `field={@form[:name]}`; `form_field/1` adds labels, descriptions and used-field
  errors around `input`, `textarea`, `native_select`, `checkbox` and `switch`.
  See `ShadcnLiveview.Form`. Sortable, filterable, paginated tables with row
  selection keep their state in a `ShadcnLiveview.DataTable.State` assign; see
  `ShadcnLiveview.DataTable`.

  ## Component families

  * Actions: `ShadcnLiveview.Components.ButtonGroup`, `ShadcnLiveview.Components.Button`, `ShadcnLiveview.Components.ToggleGroup`, `ShadcnLiveview.Components.Toggle`
  * Data display: `ShadcnLiveview.Components.Accordion`, `ShadcnLiveview.Components.Attachment`, `ShadcnLiveview.Components.Avatar`, `ShadcnLiveview.Components.Badge`, `ShadcnLiveview.Components.Card`, `ShadcnLiveview.Components.Carousel`, `ShadcnLiveview.Components.Chart`, `ShadcnLiveview.Components.Item`, `ShadcnLiveview.Components.Kbd`, `ShadcnLiveview.Components.Marker`, `ShadcnLiveview.Components.Message`, `ShadcnLiveview.Components.Questionnaire`, `ShadcnLiveview.Components.Table`
  * Feedback: `ShadcnLiveview.Components.Alert`, `ShadcnLiveview.Components.Bubble`, `ShadcnLiveview.Components.Empty`, `ShadcnLiveview.Components.Progress`, `ShadcnLiveview.Components.Skeleton`, `ShadcnLiveview.Components.Sonner`, `ShadcnLiveview.Components.Spinner`
  * Forms: `ShadcnLiveview.Components.Calendar`, `ShadcnLiveview.Components.Checkbox`, `ShadcnLiveview.Components.Combobox`, `ShadcnLiveview.Components.Command`, `ShadcnLiveview.Components.Field`, `ShadcnLiveview.Components.InputGroup`, `ShadcnLiveview.Components.InputOtp`, `ShadcnLiveview.Components.Input`, `ShadcnLiveview.Components.Label`, `ShadcnLiveview.Components.NativeSelect`, `ShadcnLiveview.Components.RadioGroup`, `ShadcnLiveview.Components.Select`, `ShadcnLiveview.Components.Slider`, `ShadcnLiveview.Components.Switch`, `ShadcnLiveview.Components.Textarea`
  * Layout: `ShadcnLiveview.Components.AspectRatio`, `ShadcnLiveview.Components.Collapsible`, `ShadcnLiveview.Components.Direction`, `ShadcnLiveview.Components.MessageScroller`, `ShadcnLiveview.Components.Resizable`, `ShadcnLiveview.Components.ScrollArea`, `ShadcnLiveview.Components.Separator`
  * Navigation: `ShadcnLiveview.Components.Breadcrumb`, `ShadcnLiveview.Components.Menubar`, `ShadcnLiveview.Components.NavigationMenu`, `ShadcnLiveview.Components.Pagination`, `ShadcnLiveview.Components.Sidebar`, `ShadcnLiveview.Components.Tabs`
  * Overlays: `ShadcnLiveview.Components.AlertDialog`, `ShadcnLiveview.Components.ContextMenu`, `ShadcnLiveview.Components.Dialog`, `ShadcnLiveview.Components.Drawer`, `ShadcnLiveview.Components.DropdownMenu`, `ShadcnLiveview.Components.HoverCard`, `ShadcnLiveview.Components.Popover`, `ShadcnLiveview.Components.Sheet`, `ShadcnLiveview.Components.Tooltip`
  * Icons: `ShadcnLiveview.Components.Icon` (Lucide)
  """

  @families [
    ShadcnLiveview.Components.Icon,
    ShadcnLiveview.Components.Accordion,
    ShadcnLiveview.Components.AlertDialog,
    ShadcnLiveview.Components.Alert,
    ShadcnLiveview.Components.AspectRatio,
    ShadcnLiveview.Components.Attachment,
    ShadcnLiveview.Components.Avatar,
    ShadcnLiveview.Components.Badge,
    ShadcnLiveview.Components.Breadcrumb,
    ShadcnLiveview.Components.Bubble,
    ShadcnLiveview.Components.ButtonGroup,
    ShadcnLiveview.Components.Button,
    ShadcnLiveview.Components.Calendar,
    ShadcnLiveview.Components.Card,
    ShadcnLiveview.Components.Carousel,
    ShadcnLiveview.Components.Chart,
    ShadcnLiveview.Components.Checkbox,
    ShadcnLiveview.Components.Collapsible,
    ShadcnLiveview.Components.Combobox,
    ShadcnLiveview.Components.Command,
    ShadcnLiveview.Components.ContextMenu,
    ShadcnLiveview.Components.Dialog,
    ShadcnLiveview.Components.Direction,
    ShadcnLiveview.Components.Drawer,
    ShadcnLiveview.Components.DropdownMenu,
    ShadcnLiveview.Components.Empty,
    ShadcnLiveview.Components.Field,
    ShadcnLiveview.Components.HoverCard,
    ShadcnLiveview.Components.InputGroup,
    ShadcnLiveview.Components.InputOtp,
    ShadcnLiveview.Components.Input,
    ShadcnLiveview.Components.Item,
    ShadcnLiveview.Components.Kbd,
    ShadcnLiveview.Components.Label,
    ShadcnLiveview.Components.Marker,
    ShadcnLiveview.Components.Menubar,
    ShadcnLiveview.Components.MessageScroller,
    ShadcnLiveview.Components.Message,
    ShadcnLiveview.Components.NativeSelect,
    ShadcnLiveview.Components.NavigationMenu,
    ShadcnLiveview.Components.Pagination,
    ShadcnLiveview.Components.Popover,
    ShadcnLiveview.Components.Progress,
    ShadcnLiveview.Components.Questionnaire,
    ShadcnLiveview.Components.RadioGroup,
    ShadcnLiveview.Components.Resizable,
    ShadcnLiveview.Components.ScrollArea,
    ShadcnLiveview.Components.Select,
    ShadcnLiveview.Components.Separator,
    ShadcnLiveview.Components.Sheet,
    ShadcnLiveview.Components.Sidebar,
    ShadcnLiveview.Components.Skeleton,
    ShadcnLiveview.Components.Slider,
    ShadcnLiveview.Components.Sonner,
    ShadcnLiveview.Components.Spinner,
    ShadcnLiveview.Components.Switch,
    ShadcnLiveview.Components.Table,
    ShadcnLiveview.Components.Tabs,
    ShadcnLiveview.Components.Textarea,
    ShadcnLiveview.Components.ToggleGroup,
    ShadcnLiveview.Components.Toggle,
    ShadcnLiveview.Components.Tooltip
  ]
  @extra_imports [
    {ShadcnLiveview.Form, [form_field: 1]},
    {ShadcnLiveview.DataTable,
     [data_table: 1, data_table_search: 1, data_table_view_options: 1, data_table_pagination: 1]}
  ]

  @doc """
  Imports every family's function components, `ShadcnLiveview.Form.form_field/1` and
  the `ShadcnLiveview.DataTable` components.

  `only:` or `except:` (mutually exclusive) take `name: arity` keyword lists
  applied across all families, as with `Kernel.import/2`. Names that are not
  imported components raise `ArgumentError`.

      use ShadcnLiveview, except: [icon: 1]
      use ShadcnLiveview, only: [button: 1, card: 1, card_content: 1]
  """
  defmacro __using__(opts) do
    imports =
      for {module, import_opts} <- import_plan(opts) do
        quote do: import(unquote(module), unquote(import_opts))
      end

    {:__block__, [], imports}
  end

  defp import_plan(opts) do
    case import_filter!(opts) do
      nil ->
        Enum.map(@families, &{&1, only: components(&1)}) ++
          Enum.map(@extra_imports, fn {module, names} -> {module, only: names} end)

      {kind, names} ->
        filtered_import_plan(kind, names)
    end
  end

  defp import_filter!(opts) do
    if not Keyword.keyword?(opts) do
      raise ArgumentError, "use ShadcnLiveview expects a keyword list, got: #{inspect(opts)}"
    end

    case Keyword.split(opts, [:only, :except]) do
      {[], []} ->
        nil

      {[{kind, names}], []} ->
        {kind, validate_names!(kind, names)}

      {_filters, []} ->
        raise ArgumentError, "use ShadcnLiveview accepts either :only or :except, not both"

      {_filters, unknown} ->
        raise ArgumentError,
              "use ShadcnLiveview got unknown options #{inspect(Keyword.keys(unknown))}; " <>
                "expected :only or :except"
    end
  end

  defp validate_names!(kind, names) do
    if Keyword.keyword?(names) and
         Enum.all?(names, fn {_name, arity} -> is_integer(arity) and arity >= 0 end) do
      names
    else
      raise ArgumentError,
            "use ShadcnLiveview expects #{kind}: to be a keyword list of name: arity, got: #{inspect(names)}"
    end
  end

  defp filtered_import_plan(kind, names) do
    exports = Enum.map(@families, &{&1, components(&1)}) ++ @extra_imports
    available = Enum.flat_map(exports, &elem(&1, 1))

    case Enum.reject(names, &(&1 in available)) do
      [] ->
        :ok

      unknown ->
        raise ArgumentError,
              "use ShadcnLiveview, #{kind}: no component family exports #{inspect(unknown)}"
    end

    Enum.flat_map(exports, fn {module, functions} ->
      kept =
        if kind == :only, do: Enum.filter(functions, &(&1 in names)), else: functions -- names

      if kept == [], do: [], else: [{module, only: kept}]
    end)
  end

  # Function components only (arity 1); module helpers such as
  # Calendar.shift_month/2 stay callable by their qualified name.
  defp components(module) do
    for {name, 1} <- Code.ensure_compiled!(module).__info__(:functions),
        not String.starts_with?(Atom.to_string(name), "_"),
        do: {name, 1}
  end
end
