defmodule ShadcnLiveview.ControlsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview

  alias Phoenix.HTML.Safe

  test "checkbox mixed state is visible but not a checked submitted form value" do
    assigns = %{}

    document =
      parse(~H"""
      <.checkbox
        id="mixed"
        checked="indeterminate"
        name="permission"
        value="allow"
        required
        form="settings"
      />
      <.checkbox id="checked" checked={true} name="permission" value="write" disabled />
      """)

    assert Floki.attribute(document, "#mixed", "aria-checked") == ["mixed"]
    assert Floki.attribute(document, "#mixed", "data-state") == ["indeterminate"]
    assert length(Floki.find(document, "#mixed svg")) == 1
    assert Floki.attribute(document, "input[checked]", "value") == ["write"]
    assert Floki.attribute(document, "input[required]", "form") == ["settings"]
    assert length(Floki.find(document, "input[disabled]")) == 1
    assert Floki.attribute(document, "button", "name") == []
  end

  test "switches preserve independent state and native form attributes" do
    assigns = %{}

    document =
      parse(~H"""
      <.switch id="mail" checked={true} size="sm" name="mail" value="enabled" form="settings" required />
      <.switch id="sms" checked={false} disabled name="sms" />
      """)

    assert Floki.attribute(document, "#mail", "aria-checked") == ["true"]

    assert Floki.attribute(document, "#mail [data-slot=switch-thumb]", "data-state") == [
             "checked"
           ]

    assert Floki.attribute(document, "#sms", "aria-checked") == ["false"]
    assert Floki.attribute(document, "input[checked]", "name") == ["mail"]
    assert Floki.attribute(document, "input[checked]", "form") == ["settings"]
    assert Floki.attribute(document, "input[disabled]", "name") == ["sms"]
    assert Floki.attribute(document, "#mail", "data-size") == ["sm"]
  end

  test "binary controls distinguish explicit false and mixed values from uncontrolled defaults" do
    assigns = %{}

    document =
      parse(~H"""
      <.checkbox id="uncontrolled-check" default_checked={true} />
      <.checkbox id="controlled-check" checked={false} default_checked={true} />
      <.checkbox id="mixed-check" checked="indeterminate" default_checked={true} />
      <.switch id="uncontrolled-switch" default_checked={true} />
      <.switch id="controlled-switch" checked={false} default_checked={true} />
      """)

    for id <- ["uncontrolled-check", "uncontrolled-switch"] do
      assert Floki.attribute(document, "##{id}", "phx-value-controlled") == ["false"]
      assert Floki.attribute(document, "##{id}", "phx-value-state") == ["checked"]
      assert Floki.attribute(document, "##{id}", "phx-value-initial") == ["checked"]
    end

    for id <- ["controlled-check", "controlled-switch"] do
      assert Floki.attribute(document, "##{id}", "phx-value-controlled") == ["true"]
      assert Floki.attribute(document, "##{id}", "phx-value-state") == ["unchecked"]
      assert Floki.attribute(document, "##{id}", "aria-checked") == ["false"]
    end

    assert Floki.attribute(document, "#mixed-check", "phx-value-controlled") == ["true"]
    assert Floki.attribute(document, "#mixed-check", "phx-value-state") == ["indeterminate"]
  end

  test "slider ranges derive from supplied bounds and values, not a midpoint constant" do
    assigns = %{}

    document =
      parse(~H"""
      <.slider id="range" value={[20, 80]} min={10} max={90} step={5} name="price" />
      <.slider id="vertical" value={[25]} min={0} max={50} orientation="vertical" disabled />
      """)

    assert Floki.attribute(document, "#range [data-slot=slider-range]", "style") == [
             "left:12.5%;right:12.5%"
           ]

    assert Floki.attribute(document, "#range input", "name") == ["price[]", "price[]"]
    assert Floki.attribute(document, "#range [role=slider]", "aria-valuemin") == ["10", "10"]
    assert Floki.attribute(document, "#range [role=slider]", "aria-valuemax") == ["90", "90"]

    assert Floki.attribute(document, "#vertical [data-slot=slider-range]", "style") == [
             "bottom:0%;top:50%"
           ]

    assert Floki.attribute(document, "#vertical [role=slider]", "tabindex") == []
    assert Floki.attribute(document, "#vertical", "dir") == ["ltr"]
    assert Floki.attribute(document, "#range", "phx-value-values") == ["[20,80]"]
    assert Floki.attribute(document, "#range", "phx-value-step") == ["5"]
  end

  test "slider SSR keeps wrapper thumbs distinct from default control values" do
    assigns = %{}

    document =
      parse(~H"""
      <.slider id="extents" min={10} max={30} name="extent" />
      <.slider id="three" value={[10, 40, 80]} name="amount" form="settings" />
      <.slider id="fractional" value={[30, 60]} min={0} max={90} disabled />
      """)

    assert length(Floki.find(document, "#extents [role=slider]")) == 2
    assert Floki.attribute(document, "#extents", "phx-value-values") == ["[10]"]
    assert Floki.attribute(document, "#extents input", "name") == ["extent", "extent"]

    assert Floki.attribute(document, "#three [role=slider]", "aria-label") == [
             "Value 0 of 3",
             "Value 0 of 3",
             "Value 0 of 3"
           ]

    assert Floki.attribute(document, "#three input", "form") == [
             "settings",
             "settings",
             "settings"
           ]

    assert Floki.attribute(document, "#fractional [data-slot=slider-range]", "style") == [
             "left:33.333333333333336%;right:33.33333333333333%"
           ]
  end

  test "slider controlled values override defaults while mounted reset defaults remain separate" do
    assigns = %{}

    document =
      parse(~H"""
      <.slider id="uncontrolled-slider" default_value={[25]} />
      <.slider id="controlled-slider" value={[40]} default_value={[25]} />
      <.slider id="empty-slider" value={[]} default_value={[25]} />
      <.slider id="implicit-slider" min={10} max={30} />
      """)

    assert Floki.attribute(document, "#uncontrolled-slider", "phx-value-controlled") == ["false"]
    assert Floki.attribute(document, "#uncontrolled-slider", "phx-value-values") == ["[25]"]
    assert Floki.attribute(document, "#uncontrolled-slider", "phx-value-initial") == ["[25]"]
    assert Floki.attribute(document, "#controlled-slider", "phx-value-controlled") == ["true"]
    assert Floki.attribute(document, "#controlled-slider", "phx-value-values") == ["[40]"]
    assert Floki.attribute(document, "#controlled-slider", "phx-value-initial") == ["[25]"]
    assert Floki.attribute(document, "#empty-slider", "phx-value-controlled") == ["true"]
    assert Floki.attribute(document, "#empty-slider", "phx-value-values") == ["[]"]
    assert Floki.attribute(document, "#implicit-slider", "phx-value-controlled") == ["false"]
    assert Floki.attribute(document, "#implicit-slider", "phx-value-values") == ["[10]"]
  end

  test "disclosure context scopes controls and closed content does not render its children" do
    assigns = %{}

    document =
      parse(~H"""
      <.collapsible :let={context} id="one" open={true}>
        <.collapsible_trigger context={context}>One</.collapsible_trigger>
        <.collapsible_content context={context}>Visible</.collapsible_content>
      </.collapsible>
      <.collapsible :let={context} id="two" disabled>
        <.collapsible_trigger context={context}>Two</.collapsible_trigger>
        <.collapsible_content context={context}><button>Absent</button></.collapsible_content>
      </.collapsible>
      """)

    assert Floki.attribute(document, "#one button", "aria-controls") == ["radix-one-content"]
    assert Floki.attribute(document, "#one button", "aria-expanded") == ["true"]
    assert Floki.attribute(document, "#two button", "aria-expanded") == ["false"]
    assert length(Floki.find(document, "#two button[disabled]")) == 1
    assert Floki.find(document, "#radix-two-content button") == []
    assert length(Floki.find(document, "#radix-two-content[hidden]")) == 1
  end

  test "navigation only renders the selected content with matching trigger relationships" do
    assigns = %{}

    document =
      parse(~H"""
      <.navigation_menu :let={context} id="navigation" value="about" viewport={false}>
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger>
            <.navigation_menu_content context={item}>Not rendered</.navigation_menu_content>
          </.navigation_menu_item>
          <.navigation_menu_item :let={item} context={context} value="about">
            <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger>
            <.navigation_menu_content context={item}>
              <.navigation_menu_link active href="/about">Company</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu>
      """)

    assert Floki.attribute(document, "[data-slot=navigation-menu-content]", "id") == [
             "radix-navigation-content-about"
           ]

    assert Floki.attribute(document, "#radix-navigation-trigger-about", "aria-controls") == [
             "radix-navigation-content-about"
           ]

    assert Floki.attribute(document, "#radix-navigation-content-about", "aria-labelledby") == [
             "radix-navigation-trigger-about"
           ]

    assert Floki.attribute(document, "a[aria-current=page]", "href") == ["/about"]
    assert Floki.find(document, "#radix-navigation-content-docs") == []
    assert Floki.attribute(document, "#radix-navigation-content-about", "style") == []
    refute Floki.text(document) =~ "Not rendered"
  end

  test "retained navigation content remains server-rendered alongside the selected viewport panel" do
    assigns = %{}

    document =
      parse(~H"""
      <.navigation_menu :let={context} id="retained-navigation" value="about">
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger>
            <.navigation_menu_content context={item} force_mount>
              <.navigation_menu_link href="/docs">Guide</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
          <.navigation_menu_item :let={item} context={context} value="about">
            <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger>
            <.navigation_menu_content context={item}>
              <.navigation_menu_link href="/about">Company</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu>
      """)

    assert Floki.attribute(document, "#radix-retained-navigation-content-docs", "style") == [
             "pointer-events:none"
           ]

    assert Floki.attribute(document, "#radix-retained-navigation-content-about", "style") == []
    assert length(Floki.find(document, "li [data-slot=navigation-menu-content] a")) == 2
    assert Floki.find(document, "[data-slot=navigation-menu-viewport] a") == []

    assert Floki.attribute(document, "[data-slot=navigation-menu-viewport]", "data-state") == [
             "open"
           ]
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
