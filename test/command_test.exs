defmodule ShadcnLiveview.CommandTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "command context links independent native search inputs to their labels and lists" do
    assigns = %{}

    document =
      parse(~H"""
      <.command :let={command} id="first-command" value="save" label="Editor">
        <.command_input context={command} name="query" value="sav" required />
        <.command_list context={command}>
          <.command_empty>No results.</.command_empty>
          <.command_group id="editor" heading="Editor">
            <.command_item id="save" value="save" keywords={["persist"]}>Save</.command_item>
            <.command_item id="delete" value="delete" disabled>Delete</.command_item>
          </.command_group>
        </.command_list>
      </.command>
      <.command :let={command} id="second-command">
        <.command_input context={command} name="other" />
        <.command_list context={command}>
          <.command_item id="open" value="open">Open</.command_item>
        </.command_list>
      </.command>
      """)

    assert Floki.attribute(document, "#first-command input", "name") == ["query"]
    assert Floki.attribute(document, "#first-command input", "value") == ["sav"]
    assert Floki.find(document, "#first-command input[required]") != []

    assert Floki.attribute(document, "#first-command input", "aria-controls") == [
             "radix-first-command-list"
           ]

    assert Floki.attribute(document, "#first-command label", "for") == [
             "radix-first-command-input"
           ]

    assert Floki.attribute(document, "#second-command input", "aria-controls") == [
             "radix-second-command-list"
           ]

    assert Floki.attribute(document, "#delete", "aria-disabled") == ["true"]
    assert Floki.attribute(document, "#save", "phx-value-value") == ["save"]
    assert Floki.attribute(document, "#save", "data-selected") == ["false"]
    assert_unique_ids(document)
  end

  test "combobox open assign owns content, selected state and unique trigger IDs" do
    for open <- [false, true] do
      assigns = %{open: open}

      document =
        parse(~H"""
        <form id="preferences">
          <.combobox id="framework" name="framework" value="phoenix" open={@open}>
            <:input :let={combo}>
              <.combobox_input context={combo} id="framework-input" show_clear />
            </:input>
            <:content :let={combo}>
              <.combobox_content context={combo}>
                <.combobox_list context={combo}>
                  <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
                  <.combobox_item context={combo} value="next" disabled>Next.js</.combobox_item>
                </.combobox_list>
                <.combobox_empty>No frameworks.</.combobox_empty>
              </.combobox_content>
            </:content>
          </.combobox>
        </form>
        """)

      assert Floki.attribute(document, "#framework-input", "value") == ["phoenix"]
      assert Floki.attribute(document, "input[name=framework]", "value") == ["phoenix"]
      assert Floki.attribute(document, "#framework", "aria-expanded") == [to_string(open)]
      assert Floki.find(document, "[data-slot=combobox-clear]") != []

      assert Floki.attribute(document, "#framework-input", "phx-value-open-event") == [
               "shadcn:combobox-open"
             ]

      assert Floki.attribute(document, "#framework-input", "phx-value-popup") == []

      if open do
        assert Floki.attribute(document, "[data-slot=combobox-content]", "id") == [
                 "radix-framework-popup"
               ]

        assert Floki.attribute(document, "[data-slot=combobox-list]", "id") == [
                 "radix-framework-list"
               ]

        assert Floki.attribute(document, "[aria-selected=true]", "phx-value-value") == ["phoenix"]

        assert Floki.attribute(
                 document,
                 "[data-slot=combobox-item][data-disabled]",
                 "phx-value-value"
               ) == ["next"]

        assert Floki.attribute(document, "#framework-input", "aria-controls") == [
                 "radix-framework-list"
               ]
      else
        assert Floki.find(document, "[data-slot=combobox-content]") == []
        assert Floki.attribute(document, "#framework-input", "aria-controls") == []
      end

      assert_unique_ids(document)
    end
  end

  test "combobox input combines root and child disabled assigns on every render" do
    for child_disabled <- [false, true], root_disabled <- [false, true, false] do
      assigns = %{root_disabled: root_disabled, child_disabled: child_disabled}

      document =
        parse(~H"""
        <.combobox
          id="disabled-framework"
          name="framework"
          value="phoenix"
          input_value="Phoenix"
          disabled={@root_disabled}
        >
          <:input :let={combo}>
            <.combobox_input
              context={combo}
              id="disabled-framework-input"
              disabled={@child_disabled}
              show_clear
            />
          </:input>
          <:content :let={combo}>
            <.combobox_content context={combo}>Options</.combobox_content>
          </:content>
        </.combobox>
        """)

      effective_disabled = root_disabled || child_disabled

      for selector <- [
            "#disabled-framework-input",
            "#disabled-framework",
            "[data-slot=combobox-clear]"
          ] do
        assert length(Floki.find(document, selector)) == 1
        assert Floki.find(document, selector <> "[disabled]") != [] == effective_disabled
        assert Floki.find(document, selector <> "[data-disabled]") != [] == effective_disabled
      end

      assert Floki.find(document, "input[name=framework][disabled]") != [] == root_disabled
      assert Floki.attribute(document, "#disabled-framework-input", "value") == ["Phoenix"]
      assert Floki.attribute(document, "input[name=framework]", "value") == ["phoenix"]
    end
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end

  defp assert_unique_ids(document) do
    ids = Floki.attribute(document, "[id]", "id")
    assert length(ids) == length(Enum.uniq(ids))
  end
end
