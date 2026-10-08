defmodule ShadcnLiveview.ModalsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "closed portals render only independent native triggers" do
    assigns = %{}

    document =
      parse(~H"""
      <.dialog id="closed-dialog" open={false}>
        <:trigger :let={modal}>
          <.dialog_trigger context={modal}>Open dialog</.dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.dialog_content context={modal}>Dialog body</.dialog_content>
        </:content>
      </.dialog>
      <.alert_dialog id="closed-alert" open={false}>
        <:trigger :let={modal}>
          <.alert_dialog_trigger context={modal}>Open alert</.alert_dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.alert_dialog_content context={modal}>Alert body</.alert_dialog_content>
        </:content>
      </.alert_dialog>
      <.drawer id="closed-drawer" open={false}>
        <:trigger :let={modal}>
          <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
        </:trigger>
        <:content :let={modal}>
          <.drawer_content context={modal}>Drawer body</.drawer_content>
        </:content>
      </.drawer>
      <.sheet id="closed-sheet" open={false}>
        <:trigger :let={modal}>
          <.sheet_trigger context={modal}>Open sheet</.sheet_trigger>
        </:trigger>
        <:content :let={modal}>
          <.sheet_content context={modal}>Sheet body</.sheet_content>
        </:content>
      </.sheet>
      """)

    assert length(Floki.find(document, "button[type=button][aria-expanded=false]")) == 4

    assert Floki.find(document, "[role=dialog], [role=alertdialog], [aria-controls], template") ==
             []

    assert Floki.find(document, "[data-slot$=-overlay], button button") == []

    for id <- ~w(closed-dialog closed-alert closed-drawer closed-sheet) do
      [command] = Floki.attribute(document, "##{id}-trigger", "phx-click")

      assert [["push", %{"event" => "shadcn:modal-open", "value" => %{"id" => ^id}}]] =
               Jason.decode!(command)
    end
  end

  test "custom IDs preserve content, trigger and description relationships" do
    assigns = %{}

    document =
      parse(~H"""
      <.dialog id="editor" open title_id="editor-heading" description_id="editor-help">
        <:trigger :let={modal}>
          <.dialog_trigger context={modal}>Edit</.dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.dialog_content
            context={modal}
            aria-labelledby="editor-heading"
            aria-describedby="editor-help"
            show_close_button={false}
          >
            <.dialog_title context={modal}>Profile</.dialog_title>
            <.dialog_description context={modal}>Edit your profile.</.dialog_description>
            <.dialog_close context={modal} name="dismiss" value="cancel">Dismiss</.dialog_close>
          </.dialog_content>
        </:content>
      </.dialog>
      <.dialog id="second-editor" open={false}>
        <:trigger :let={modal}>
          <.dialog_trigger context={modal}>Second</.dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.dialog_content context={modal}>Second body</.dialog_content>
        </:content>
      </.dialog>
      """)

    assert Floki.attribute(document, "#editor-trigger", "aria-controls") == ["editor"]
    assert Floki.attribute(document, "#editor", "aria-labelledby") == ["editor-heading"]
    assert Floki.attribute(document, "#editor", "aria-describedby") == ["editor-help"]
    assert Floki.attribute(document, "[data-slot=dialog-title]", "id") == ["editor-heading"]
    assert Floki.attribute(document, "[data-slot=dialog-description]", "id") == ["editor-help"]
    assert Floki.find(document, "#second-editor, button button") == []

    assert length(Floki.find(document, "[data-slot=dialog-close][name=dismiss][value=cancel]")) ==
             1

    assert Floki.attribute(document, "#editor", "phx-value-trigger-id") == ["editor-trigger"]
  end

  test "alert actions retain variants, form semantics and close commands" do
    assigns = %{}

    document =
      parse(~H"""
      <.alert_dialog id="confirmation" open>
        <:content :let={modal}>
          <.alert_dialog_content context={modal} size="sm">
            <.alert_dialog_title context={modal}>Confirm</.alert_dialog_title>
            <.alert_dialog_description context={modal}>This is permanent.</.alert_dialog_description>
            <.alert_dialog_footer>
              <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
              <.alert_dialog_action
                context={modal}
                variant="destructive"
                size="sm"
                type="submit"
                form="account"
                name="action"
                value="delete"
                disabled
              >
                Delete
              </.alert_dialog_action>
            </.alert_dialog_footer>
          </.alert_dialog_content>
        </:content>
      </.alert_dialog>
      """)

    assert Floki.attribute(document, "#confirmation", "role") == ["alertdialog"]
    assert Floki.attribute(document, "#confirmation", "data-size") == ["sm"]
    assert Floki.find(document, "button button") == []

    assert length(
             Floki.find(
               document,
               "button[type=submit][form=account][name=action][value=delete][disabled]"
             )
           ) == 1

    assert Floki.attribute(document, "[data-slot=alert-dialog-action]", "data-variant") == [
             "destructive"
           ]

    [command] = Floki.attribute(document, "[data-slot=alert-dialog-cancel]", "phx-click")

    assert [["push", %{"event" => "shadcn:modal-close", "value" => %{"id" => "confirmation"}}]] =
             Jason.decode!(command)
  end

  test "sheet sides and drawer direction stay per-instance" do
    assigns = %{}

    document =
      parse(~H"""
      <.sheet id="left-sheet" open>
        <:content :let={modal}>
          <.sheet_content context={modal} side="left" show_close_button={false}>
            <.sheet_title context={modal}>Left panel</.sheet_title>
            <.sheet_description context={modal}>From the left.</.sheet_description>
            <.sheet_close context={modal}>Close panel</.sheet_close>
          </.sheet_content>
        </:content>
      </.sheet>
      <.drawer id="top-drawer" open direction="top" dismissible={false}>
        <:content :let={modal}>
          <.drawer_content context={modal}>
            <.drawer_title context={modal}>Top drawer</.drawer_title>
            <.drawer_description context={modal}>From the top.</.drawer_description>
          </.drawer_content>
        </:content>
      </.drawer>
      """)

    assert Floki.attribute(document, "#left-sheet", "data-side") == ["left"]
    assert length(Floki.find(document, "[data-slot=sheet-close]")) == 1
    assert Floki.attribute(document, "#top-drawer", "data-vaul-drawer-direction") == ["top"]
    assert Floki.attribute(document, "#top-drawer", "phx-value-dismissible") == ["false"]
    assert Floki.attribute(document, "#top-drawer", "phx-value-draggable") == ["true"]
    assert Floki.attribute(document, "#top-drawer", "phx-modal-close") == ["[]"]
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_document!()
  end
end
