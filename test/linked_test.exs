defmodule ShadcnLiveview.LinkedTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Phoenix.Component
  alias Phoenix.HTML.Safe
  import ShadcnLiveview.Components.Accordion
  import ShadcnLiveview.Components.Tabs

  test "accordion selection transitions respect single, multiple and collapsible state" do
    assert accordion_next_value(nil, "details", "single", false) == "details"
    assert accordion_next_value("details", "details", "single", false) == "details"
    assert accordion_next_value("details", "details", "single", true) == nil
    assert accordion_next_value(["intro"], "details", "multiple", false) == ["intro", "details"]
    assert accordion_next_value(["intro", "details"], "intro", "multiple", false) == ["details"]
  end

  test "closed accordion slots render when the server changes value" do
    for value <- [nil, "details"] do
      assigns = %{value: value}

      document =
        parse(~H"""
        <.accordion :let={accordion} id="sections" value={@value} collapsible>
          <.accordion_item :let={item} context={accordion} value="details">
            <.accordion_trigger context={item}>Details</.accordion_trigger>
            <.accordion_content context={item}>
              <p>Server rendered details</p>
            </.accordion_content>
          </.accordion_item>
        </.accordion>
        """)

      assert Floki.attribute(document, "#sections-details-content", "aria-labelledby") == [
               "sections-details-trigger"
             ]

      if value do
        assert Floki.attribute(document, "#sections-details-trigger", "aria-controls") == [
                 "sections-details-content"
               ]

        assert Floki.find(document, "#sections-details-content p") != []
        assert Floki.find(document, "#sections-details-content[hidden]") == []
      else
        assert Floki.find(document, "#sections-details-content[hidden]") != []
        assert Floki.find(document, "#sections-details-content p") == []
        assert Floki.attribute(document, "#sections-details-trigger", "aria-controls") == []
      end
    end
  end

  test "accordion disabled context and force mount propagate without losing ARIA links" do
    assigns = %{}

    document =
      parse(~H"""
      <.accordion :let={accordion} id="disabled" disabled>
        <.accordion_item :let={item} context={accordion} value="details">
          <.accordion_trigger context={item}>Details</.accordion_trigger>
          <.accordion_content context={item} force_mount>Retained content</.accordion_content>
        </.accordion_item>
      </.accordion>
      """)

    assert Floki.find(document, "#disabled-details-trigger[disabled][data-disabled]") != []
    assert Floki.find(document, "#disabled-details-content[hidden]") == []
    assert Floki.text(Floki.find(document, "#disabled-details-content")) =~ "Retained content"
  end

  test "tabs controlled nil overrides defaults and SSR roving registration starts at minus one" do
    assigns = %{}

    document =
      parse(~H"""
      <.tabs :let={tabs} id="unselected" value={nil} default_value="history">
        <.tabs_list context={tabs}>
          <.tabs_trigger context={tabs} value="history">History</.tabs_trigger>
        </.tabs_list>
        <.tabs_content context={tabs} value="history">Not selected</.tabs_content>
      </.tabs>
      """)

    assert Floki.attribute(document, "#unselected-history-trigger", "aria-selected") == ["false"]
    assert Floki.attribute(document, "#unselected-history-trigger", "tabindex") == ["-1"]
    assert Floki.find(document, "#unselected-history-content[hidden]") != []
    refute Floki.text(document) =~ "Not selected"
  end

  test "tab panels mount from server state and independent roots own unique ARIA relationships" do
    for value <- ["overview", "history"] do
      assigns = %{value: value}

      document =
        parse(~H"""
        <.tabs :let={tabs} id="first" value={@value}>
          <.tabs_list context={tabs}>
            <.tabs_trigger context={tabs} value="overview">Overview</.tabs_trigger>
            <.tabs_trigger context={tabs} value="history">History</.tabs_trigger>
          </.tabs_list>
          <.tabs_content context={tabs} value="overview">
            <p>Overview content</p>
          </.tabs_content>
          <.tabs_content context={tabs} value="history">
            <p>History content</p>
          </.tabs_content>
        </.tabs>
        <.tabs :let={tabs} id="second" default_value="history">
          <.tabs_list context={tabs}>
            <.tabs_trigger context={tabs} value="history">Other history</.tabs_trigger>
          </.tabs_list>
          <.tabs_content context={tabs} value="history">Independent history</.tabs_content>
        </.tabs>
        """)

      ids = Floki.attribute(document, "[id]", "id")
      assert length(ids) == length(Enum.uniq(ids))
      assert Floki.find(document, "#first-#{value}-content p") != []
      assert Floki.attribute(document, "#first-#{value}-trigger", "aria-selected") == ["true"]

      assert Floki.attribute(document, "#second-history-trigger", "aria-controls") == [
               "second-history-content"
             ]

      assert Floki.attribute(document, "#second-history-content", "aria-labelledby") == [
               "second-history-trigger"
             ]
    end
  end

  test "tab navigation orientation and force mount are explicit context state" do
    assigns = %{}

    document =
      parse(~H"""
      <.tabs :let={tabs} id="vertical" orientation="vertical" navigation_orientation="vertical">
        <.tabs_list context={tabs} variant="line">
          <.tabs_trigger context={tabs} value="settings" disabled>Settings</.tabs_trigger>
        </.tabs_list>
        <.tabs_content context={tabs} value="settings" force_mount>Mounted settings</.tabs_content>
      </.tabs>
      """)

    assert Floki.attribute(document, "[role=tablist]", "aria-orientation") == ["vertical"]
    assert Floki.find(document, "#vertical-settings-trigger[disabled]") != []
    assert Floki.find(document, "#vertical-settings-content[hidden]") == []
    assert Floki.text(Floki.find(document, "#vertical-settings-content")) =~ "Mounted settings"
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_document!()
  end
end
