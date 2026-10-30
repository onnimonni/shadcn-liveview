defmodule ShadcnLiveview.HookTargetsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview

  alias Phoenix.HTML.Safe
  alias Phoenix.LiveView.JS

  test "calendar root phx-target reaches native navigation and selection commands" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 7}}

    document =
      parse(~H"""
      <.calendar
        id="targeted-calendar"
        month={~D[2024-02-01]}
        today={~D[2024-02-15]}
        mode="single"
        phx-target={@myself}
      />
      """)

    assert Floki.attribute(document, "#targeted-calendar", "phx-target") == ["7"]
    commands = Floki.attribute(document, "#targeted-calendar button[phx-click]", "phx-click")
    assert length(commands) > 2

    events =
      Enum.map(commands, fn command ->
        assert [["push", %{"target" => 7, "event" => event, "value" => values}]] =
                 Jason.decode!(command)

        assert values["id"] == "targeted-calendar"
        event
      end)

    assert "calendar-month" in events
    assert "calendar-select" in events
  end

  test "wrapperless popup roots forward phx-target onto custom native trigger owners" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 9}}

    document =
      parse(~H"""
      <.popover id="targeted-popover" phx-target={@myself}>
        <:trigger :let={popup}>
          <button {popup.trigger}>Open</button>
        </:trigger>
        <:content :let={popup}>
          <.popover_content context={popup}>Content</.popover_content>
        </:content>
      </.popover>
      <.tooltip id="targeted-tooltip" phx-target={@myself}>
        <:trigger :let={popup}>
          <button {popup.trigger}>Help</button>
        </:trigger>
        <:content :let={popup}>
          <.tooltip_content context={popup}>Tooltip</.tooltip_content>
        </:content>
      </.tooltip>
      """)

    for id <- ~w(targeted-popover targeted-tooltip) do
      assert Floki.attribute(document, "##{id}-trigger", "phx-target") == ["9"]

      assert Floki.attribute(document, "##{id}-trigger", "phx-popup-event") == [
               "shadcn:popup-change"
             ]
    end

    assert Floki.find(document, "button button") == []
  end

  test "modal context forwards root phx-target and preserves action-before-close order" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 11}}

    document =
      parse(~H"""
      <.dialog id="targeted-dialog" open phx-target={@myself}>
        <:trigger :let={modal}>
          <.dialog_trigger context={modal}>Toggle</.dialog_trigger>
        </:trigger>
        <:content :let={modal}>
          <.dialog_content context={modal} show_close_button={false}>
            <.dialog_close context={modal} on_click={JS.dispatch("before-close")}>
              Close
            </.dialog_close>
          </.dialog_content>
        </:content>
      </.dialog>
      <.sheet id="targeted-sheet" phx-target={@myself}>
        <:trigger :let={modal}>
          <.sheet_trigger context={modal}>Open</.sheet_trigger>
        </:trigger>
        <:content :let={modal}>
          <.sheet_content context={modal}>Sheet</.sheet_content>
        </:content>
      </.sheet>
      """)

    for selector <- [
          "#targeted-dialog",
          "#targeted-dialog-trigger",
          "[data-slot=dialog-overlay]",
          "[data-slot=dialog-close]"
        ] do
      assert Floki.attribute(document, selector, "phx-target") == ["11"]
    end

    # An explicit target is final; only untargeted controls inherit at click time.
    assert Floki.find(document, "[phx-inherit-target]") == []

    assert Floki.attribute(document, "#targeted-dialog", "phx-modal-close-event") == [
             "shadcn:modal-close"
           ]

    [close] = Floki.attribute(document, "[data-slot=dialog-close]", "phx-click")

    assert [
             ["dispatch", %{"event" => "before-close"}],
             [
               "push",
               %{
                 "event" => "shadcn:modal-close",
                 "target" => 11,
                 "value" => %{"id" => "targeted-dialog"}
               }
             ]
           ] = Jason.decode!(close)

    [open] = Floki.attribute(document, "#targeted-sheet-trigger", "phx-click")

    assert [
             [
               "push",
               %{
                 "event" => "shadcn:modal-open",
                 "target" => 11,
                 "value" => %{"id" => "targeted-sheet"}
               }
             ]
           ] =
             Jason.decode!(open)
  end

  test "untargeted modal controls inherit the nearest phx-target and close accepts button styles" do
    assigns = %{}

    document =
      parse(~H"""
      <.drawer id="inherit-drawer" open>
        <:trigger :let={modal}>
          <.drawer_trigger context={modal}>Open</.drawer_trigger>
        </:trigger>
        <:content :let={modal}>
          <.drawer_content context={modal}>
            <.drawer_close context={modal} variant="outline" size="sm">Done</.drawer_close>
            <.drawer_close context={modal} id="plain-close">Plain</.drawer_close>
          </.drawer_content>
        </:content>
      </.drawer>
      """)

    for selector <- [
          "#inherit-drawer-trigger",
          "[data-slot=drawer-overlay]",
          "[data-slot=drawer-close]"
        ] do
      assert Floki.find(document, selector <> "[phx-inherit-target]") != []
      assert Floki.attribute(document, selector, "phx-target") == []
    end

    [styled] = Floki.find(document, "[data-slot=drawer-close][data-variant=outline]")
    assert Floki.attribute(styled, "data-size") == ["sm"]
    [class] = Floki.attribute(styled, "class")
    assert class =~ "border-border" and class =~ "h-7"
    assert Floki.attribute(document, "#plain-close", "class") in [[], [""]]
    assert Floki.attribute(document, "#plain-close", "data-variant") == []
  end

  test "caller-supplied modal JS retains its explicitly selected target" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 13}}

    document =
      parse(~H"""
      <.dialog
        id="custom-modal"
        open
        phx-target={@myself}
        on_close={JS.dispatch("closing") |> JS.push("custom-close", target: "#other-owner")}
      >
        <:content :let={modal}>
          <.dialog_content context={modal} show_close_button={false}>
            <.dialog_close context={modal}>Close</.dialog_close>
          </.dialog_content>
        </:content>
      </.dialog>
      """)

    assert Floki.attribute(document, "#custom-modal", "phx-target") == ["13"]
    assert Floki.attribute(document, "#custom-modal", "phx-modal-close-event") == []
    [command] = Floki.attribute(document, "#custom-modal", "phx-modal-close")

    assert [
             ["dispatch", %{"event" => "closing"}],
             ["push", %{"event" => "custom-close", "target" => "#other-owner"}]
           ] = Jason.decode!(command)
  end

  defp parse(rendered),
    do: rendered |> Safe.to_iodata() |> IO.iodata_to_binary() |> Floki.parse_fragment!()
end
