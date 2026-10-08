defmodule ShadcnLiveview.SelectionsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "controlled radio selection preserves native form values and disabled state" do
    assigns = %{}

    document =
      parse(~H"""
      <.radio_group
        :let={group}
        id="plan"
        value="pro"
        default_value="basic"
        name="plan"
        form="external"
        required
        orientation="vertical"
      >
        <.radio_group_item id="basic" context={group} value="basic" />
        <.radio_group_item id="pro" context={group} value="pro" disabled />
      </.radio_group>
      """)

    assert Floki.attribute(document, "button[aria-checked=true]", "id") == ["pro"]
    assert Floki.attribute(document, "input[checked]", "value") == ["pro"]
    assert Floki.attribute(document, "input", "name") == ["plan", "plan"]
    assert Floki.attribute(document, "input", "form") == ["external", "external"]
    assert length(Floki.find(document, "input[required]")) == 2
    assert length(Floki.find(document, "button[disabled]")) == 1
    assert length(Floki.find(document, "input[disabled]")) == 1
    assert Floki.attribute(document, "button", "data-orientation") == ["vertical", "vertical"]
  end

  test "toggle contexts preserve single and multiple selections without nested buttons" do
    assigns = %{}

    document =
      parse(~H"""
      <.toggle_group
        :let={group}
        id="single"
        type="single"
        value="a"
        default_value="b"
        variant="outline"
        size="sm"
        spacing={0}
      >
        <.toggle_group_item id="single-a" context={group} value="a">A</.toggle_group_item>
        <.toggle_group_item id="single-b" context={group} value="b">B</.toggle_group_item>
      </.toggle_group>
      <.toggle_group :let={group} id="multiple" type="multiple" default_value={["a", "b"]} disabled>
        <.toggle_group_item id="multiple-a" context={group} value="a">A</.toggle_group_item>
        <.toggle_group_item id="multiple-b" context={group} value="b">B</.toggle_group_item>
      </.toggle_group>
      """)

    assert Floki.attribute(document, "#single button[aria-checked=true]", "id") == ["single-a"]

    assert Floki.attribute(document, "#multiple button[aria-pressed=true]", "id") == [
             "multiple-a",
             "multiple-b"
           ]

    assert Floki.attribute(document, "#single button", "data-variant") == ["outline", "outline"]
    assert Floki.attribute(document, "#single button", "data-size") == ["sm", "sm"]
    assert Floki.attribute(document, "#single button", "data-spacing") == ["0", "0"]
    assert length(Floki.find(document, "#multiple button[disabled]")) == 2
    assert Floki.find(document, "button button") == []
  end

  test "menubar mounts only the selected server-rendered menu and preserves ID relationships" do
    assigns = %{}

    document =
      parse(~H"""
      <.menubar :let={bar} id="menus" value="edit">
        <.menubar_menu id="file" value="file" context={bar}>
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>File</.menubar_trigger>
          </:trigger>
          <:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>New</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
        <.menubar_menu
          id="edit"
          value="edit"
          context={bar}
          trigger_id="edit-trigger"
          content_id="edit-content"
        >
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>Edit</.menubar_trigger>
          </:trigger>
          <:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>Undo</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
      </.menubar>
      """)

    assert Floki.attribute(document, "[role=menu]", "id") == ["edit-content"]
    assert Floki.attribute(document, "#edit-trigger", "aria-controls") == ["edit-content"]
    assert Floki.attribute(document, "#edit-content", "aria-labelledby") == ["edit-trigger"]
    assert Floki.attribute(document, "#radix-file-trigger", "aria-expanded") == ["false"]
    assert Floki.find(document, "[phx-menu-content], template") == []
    assert Floki.find(document, "button button") == []
  end

  test "menu checkbox and radio indicators represent their actual assigned state" do
    assigns = %{}

    document =
      parse(~H"""
      <.menubar_checkbox_item id="mixed" checked="indeterminate">Mixed</.menubar_checkbox_item>
      <.menubar_radio_group :let={group} id="theme" value="dark">
        <.menubar_radio_item id="light" context={group} value="light">Light</.menubar_radio_item>
        <.menubar_radio_item id="dark" context={group} value="dark" disabled>Dark</.menubar_radio_item>
      </.menubar_radio_group>
      """)

    assert Floki.attribute(document, "#mixed", "aria-checked") == ["mixed"]
    assert Floki.attribute(document, "#mixed", "data-state") == ["indeterminate"]
    assert length(Floki.find(document, "#mixed svg")) == 1
    assert Floki.find(document, "#light svg") == []
    assert Floki.attribute(document, "#dark", "aria-checked") == ["true"]
    assert Floki.attribute(document, "#dark", "aria-disabled") == ["true"]
    assert length(Floki.find(document, "#dark svg")) == 1
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
