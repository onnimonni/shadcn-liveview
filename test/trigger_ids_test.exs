defmodule ShadcnLiveview.TriggerIdsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "a root trigger_id renames the dialog trigger and focus return follows it" do
    assigns = %{}

    html =
      render(~H"""
      <.dialog id="editor" open trigger_id="edit-profile">
        <:trigger :let={modal}>
          <.dialog_trigger context={modal}>Edit</.dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.dialog_content context={modal}>Body</.dialog_content>
        </:content>
      </.dialog>
      """)

    document = Floki.parse_document!(html)
    assert Floki.attribute(document, "[data-slot=dialog-trigger]", "id") == ["edit-profile"]
    assert Floki.attribute(document, "#editor", "phx-value-trigger-id") == ["edit-profile"]
    assert Floki.attribute(document, "#edit-profile", "aria-controls") == ["editor"]
    assert single_ids?(html)
  end

  test "a dialog-family trigger id equal to the root's renders once" do
    assigns = %{}

    html =
      render(~H"""
      <.sheet id="filters" trigger_id="filters-button">
        <:trigger :let={modal}>
          <.sheet_trigger id="filters-button" context={modal}>Filters</.sheet_trigger>
        </:trigger>
        <:content :let={modal}>
          <.sheet_content context={modal}>Body</.sheet_content>
        </:content>
      </.sheet>
      """)

    assert Floki.attribute(Floki.parse_document!(html), "button", "id") == ["filters-button"]
    assert single_ids?(html)
  end

  test "a different id on a dialog-family trigger raises with the root-level fix" do
    assigns = %{}

    error =
      assert_raise ArgumentError, fn ->
        render(~H"""
        <.dialog id="editor">
          <:trigger :let={modal}>
            <.dialog_trigger id="edit-profile" context={modal}>Edit</.dialog_trigger>
          </:trigger>
          <:content :let={modal}>
            <.dialog_content context={modal}>Body</.dialog_content>
          </:content>
        </.dialog>
        """)
      end

    assert error.message =~ ~s(<.dialog_trigger> received id="edit-profile")
    assert error.message =~ ~s("editor-trigger")
    assert error.message =~ ~s(trigger_id="edit-profile")
  end

  test "a popup root trigger_id renames the spread trigger and every relation follows it" do
    assigns = %{}

    html =
      render(~H"""
      <.dropdown_menu id="row-menu" open trigger_id="row-actions">
        <:trigger :let={popup}>
          <.button variant="ghost" {popup.trigger}>Actions</.button>
        </:trigger>
        <:content :let={popup}>
          <.dropdown_menu_content context={popup}>
            <.dropdown_menu_item value="edit">Edit</.dropdown_menu_item>
          </.dropdown_menu_content>
        </:content>
      </.dropdown_menu>
      <.select id="plan" trigger_id="plan-input" value="pro">
        <:trigger :let={select}>
          <.select_trigger context={select}><.select_value context={select} /></.select_trigger>
        </:trigger>
        <:option id="pro" value="pro" label="Pro">Pro</:option>
      </.select>
      """)

    document = Floki.parse_document!(html)
    assert Floki.attribute(document, "[data-slot=dropdown-menu-trigger]", "id") == ["row-actions"]

    assert Floki.attribute(document, "#row-actions", "phx-popup-trigger-id") == ["row-actions"]
    assert Floki.attribute(document, "#row-actions", "aria-controls") == ["row-menu-content"]
    assert Floki.attribute(document, "#row-menu-content", "aria-labelledby") == ["row-actions"]
    assert Floki.attribute(document, "[data-slot=select-trigger]", "id") == ["plan-input"]
    assert single_ids?(html)
  end

  test "a caller id beside a spread trigger context raises instead of rendering two ids" do
    assigns = %{}

    error =
      assert_raise ArgumentError, fn ->
        render(~H"""
        <.popover id="share">
          <:trigger :let={popup}>
            <.button id="share-button" {popup.trigger}>Share</.button>
          </:trigger>
          <:content :let={popup}>
            <.popover_content context={popup}>Body</.popover_content>
          </:content>
        </.popover>
        """)
      end

    assert error.message =~ ~s(<.button> received id="share-button")
    assert error.message =~ ~s(trigger_id="share-button")

    assert_raise ArgumentError, ~r/<\.select_trigger> received id="plan-button"/, fn ->
      render(~H"""
      <.select id="plan" value="pro">
        <:trigger :let={select}>
          <.select_trigger id="plan-button" context={select}>
            <.select_value context={select} />
          </.select_trigger>
        </:trigger>
        <:option id="pro" value="pro" label="Pro">Pro</:option>
      </.select>
      """)
    end

    assert_raise ArgumentError, ~r/<\.context_menu_trigger> received id="area"/, fn ->
      render(~H"""
      <.context_menu id="canvas">
        <:trigger :let={popup}>
          <.context_menu_trigger id="area" context={popup}>Right click</.context_menu_trigger>
        </:trigger>
        <:content :let={popup}>
          <.context_menu_content context={popup}>
            <.context_menu_item value="copy">Copy</.context_menu_item>
          </.context_menu_content>
        </:content>
      </.context_menu>
      """)
    end
  end

  test "a matching caller id beside a spread trigger context renders once" do
    assigns = %{}

    html =
      render(~H"""
      <.tooltip id="help" trigger_id="help-button">
        <:trigger :let={popup}>
          <.button id="help-button" {popup.trigger}>Help</.button>
        </:trigger>
        <:content :let={popup}>
          <.tooltip_content context={popup}>Tip</.tooltip_content>
        </:content>
      </.tooltip>
      """)

    assert Floki.attribute(Floki.parse_document!(html), "button", "id") == ["help-button"]
    assert single_ids?(html)
  end

  defp render(rendered), do: rendered |> Safe.to_iodata() |> IO.iodata_to_binary()

  # Floki keeps one of several same-named attributes; check the raw tags instead.
  defp single_ids?(html) do
    Regex.scan(~r/<[a-z][^>]*>/, html)
    |> List.flatten()
    |> Enum.all?(&(length(Regex.scan(~r/\sid="/, &1)) <= 1))
  end
end
