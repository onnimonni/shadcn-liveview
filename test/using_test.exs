defmodule ShadcnLiveview.UsingTest do
  use ExUnit.Case, async: true

  alias ShadcnLiveview.Components.{Accordion, Button, Calendar, Card, Icon}

  defmodule OnlyButton do
    use ShadcnLiveview, only: [button: 1]
    def imports, do: __ENV__.functions
  end

  defmodule ExceptIcon do
    use ShadcnLiveview, except: [icon: 1]
    def imports, do: __ENV__.functions
  end

  defmodule Everything do
    use ShadcnLiveview
    def imports, do: __ENV__.functions
  end

  defmodule CoreLike do
    use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1, data_table_search: 1]
    def imports, do: __ENV__.functions
  end

  defp imported(module), do: Map.new(module.imports())

  test "only: imports just the named functions across families" do
    imports = imported(OnlyButton)

    assert imports[Button] == [button: 1]
    refute Map.has_key?(imports, Card)
    refute Map.has_key?(imports, Icon)
    refute Map.has_key?(imports, ShadcnLiveview.Form)
    refute Map.has_key?(imports, ShadcnLiveview.DataTable)
  end

  test "except: keeps every other family, including form_field/1" do
    imports = imported(ExceptIcon)

    refute Map.has_key?(imports, Icon)
    assert imports[Button] == [button: 1]
    assert {:card, 1} in imports[Card]
    assert imports[ShadcnLiveview.Form] == [form_field: 1]

    assert Enum.sort(imports[ShadcnLiveview.DataTable]) == [
             data_table: 1,
             data_table_pagination: 1,
             data_table_search: 1,
             data_table_view_options: 1
           ]
  end

  test "default imports function components only, not module helpers" do
    imports = imported(Everything)

    assert imports[Button] == [button: 1]
    assert {:calendar, 1} in imports[Calendar]
    refute {:shift_month, 2} in imports[Calendar]
    assert {:accordion, 1} in imports[Accordion]
    refute {:accordion_next_value, 4} in imports[Accordion]
    assert imports[ShadcnLiveview.Form] == [form_field: 1]
    assert {:data_table, 1} in imports[ShadcnLiveview.DataTable]
    refute {:apply, 2} in imports[ShadcnLiveview.DataTable]

    for {module, functions} <- imports,
        String.starts_with?(inspect(module), "ShadcnLiveview."),
        {_name, arity} <- functions,
        do: assert(arity == 1)
  end

  test "invalid option combinations raise ArgumentError" do
    assert_raise ArgumentError, ~r/either :only or :except/, fn ->
      compile_use("only: [button: 1], except: [icon: 1]")
    end

    assert_raise ArgumentError, ~r/unknown options \[:import\]/, fn ->
      compile_use("import: [button: 1]")
    end

    assert_raise ArgumentError, ~r/keyword list of name: arity/, fn ->
      compile_use("only: [:button]")
    end
  end

  test "unknown function names raise ArgumentError listing them" do
    assert_raise ArgumentError, ~r/no component family exports \[buton: 1, button: 2\]/, fn ->
      compile_use("except: [buton: 1, button: 2, icon: 1]")
    end
  end

  test "module helpers are not importable by name" do
    assert_raise ArgumentError, ~r/no component family exports \[shift_month: 2\]/, fn ->
      compile_use("only: [shift_month: 2]")
    end
  end

  test "data table components filter like any family beside the CoreComponents four" do
    imports = imported(CoreLike)

    assert {:data_table, 1} in imports[ShadcnLiveview.DataTable]
    refute {:data_table_search, 1} in imports[ShadcnLiveview.DataTable]
    refute {:table, 1} in imports[ShadcnLiveview.Components.Table]
    assert {:table_row, 1} in imports[ShadcnLiveview.Components.Table]
  end

  defp compile_use(options) do
    module = "ShadcnLiveview.UsingTest.Invalid#{System.unique_integer([:positive])}"
    Code.compile_string("defmodule #{module} do\n  use ShadcnLiveview, #{options}\nend")
  end
end
