defmodule ShadcnLiveview.ComponentsControlsBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: [click_button: 4]
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  test "checkbox mouse keyboard mixed and external successful form values", %{conn: conn} do
    read = role("checkbox", "Read")
    write = role("checkbox", "Write")

    conn =
      conn
      |> open_fixture("checkbox-multiple-external-form")
      |> assert_checked(read)
      |> assert_checked(write, false)
      |> assert_form("#checkbox-external", [["permissions[]", "read"]])
      |> click(write)
      |> assert_attribute(write, "phx-value-state", "checked")
      |> assert_checked(write)
      |> assert_form("#checkbox-external", [["permissions[]", "read"], ["permissions[]", "write"]])
      |> focus(write)
      |> key("Space")
      |> assert_attribute(write, "phx-value-state", "unchecked")
      |> assert_checked(write, false)
      |> assert_checked(read)
      |> assert_form("#checkbox-external", [["permissions[]", "read"]])

    mixed = role("checkbox", "Permission")

    conn
    |> open_fixture("checkbox-indeterminate-enabled")
    |> assert_attribute(mixed, "aria-checked", "mixed")
    |> assert_form("#checkbox-indeterminate-enabled-form", [])
    |> focus(mixed)
    |> key("Space")
    |> assert_attribute(mixed, "phx-value-state", "checked")
    |> assert_checked(mixed)
    |> assert_form("#checkbox-indeterminate-enabled-form", [["permission", "allow"]])
  end

  test "external checkbox reset changes submission but retains visual state", %{conn: conn} do
    conn
    |> open_fixture("checkbox-multiple-external-form")
    |> assert_checked("#permission-write", false)
    |> click("#permission-write")
    |> assert_attribute("#permission-write", "phx-value-state", "checked")
    |> assert_checked("#permission-write")
    |> assert_form("#checkbox-external", [["permissions[]", "read"], ["permissions[]", "write"]])
    |> click("#checkbox-external button[type=reset]")
    |> assert_form("#checkbox-external", [["permissions[]", "read"]])
    |> assert_checked("#permission-write")
    |> assert_checked("#permission-read")
    |> click("#permission-write")
    |> assert_attribute("#permission-write", "phx-value-state", "unchecked")
    |> assert_checked("#permission-write", false)
    |> assert_form("#checkbox-external", [["permissions[]", "read"]])
  end

  test "switch independent sizes toggle and restore mounted visual and submitted defaults", %{
    conn: conn
  } do
    conn =
      conn
      |> open_fixture("switch-multiple-external-form")
      |> assert_checked("#switch-mail")
      |> assert_checked("#switch-sms", false)

    mail = box(conn, "#switch-mail")
    sms = box(conn, "#switch-sms")
    assert mail["width"] >= 24 and mail["width"] <= 60
    assert sms["width"] >= 20 and sms["width"] < mail["width"] and sms["height"] >= 12

    conn
    |> focus("#switch-mail")
    |> key("Space")
    |> assert_attribute("#switch-mail", "phx-value-state", "unchecked")
    |> click("#switch-sms")
    |> assert_attribute("#switch-sms", "phx-value-state", "checked")
    |> assert_checked("#switch-mail", false)
    |> assert_checked("#switch-sms")
    |> assert_form("#switch-settings", [["sms", "on"]])
    |> click("#switch-settings button[type=reset]")
    |> assert_attribute("#switch-mail", "phx-value-state", "checked")
    |> assert_attribute("#switch-sms", "phx-value-state", "unchecked")
    |> assert_checked("#switch-mail")
    |> assert_checked("#switch-sms", false)
    |> assert_form("#switch-settings", [["mail", "on"]])
  end

  test "slider consecutive keyboard acknowledgements preserve focus step bounds and submission",
       %{conn: conn} do
    conn = open_fixture(conn, "slider-external-form")
    track = box(conn, "#slider-external")
    thumb = box(conn, "#slider-external [role=slider]")
    assert track["width"] >= 180 and track["width"] <= 400 and track["height"] >= 4
    assert thumb["width"] >= 12 and thumb["height"] >= 12

    conn =
      conn
      |> assert_attribute("#slider-external [role=slider]", "aria-valuenow", "2")
      |> focus("#slider-external [role=slider]")

    for {key, value} <- [
          {"ArrowRight", "2.25"},
          {"End", "10"},
          {"ArrowRight", "10"},
          {"Home", "0"},
          {"ArrowLeft", "0"},
          {"ArrowRight", "0.25"}
        ] do
      conn
      |> key(key)
      |> assert_attribute("#slider-external", "phx-value-values", "[#{value}]")
      |> assert_attribute("#slider-external [role=slider]", "aria-valuenow", value)
      |> assert_focused("#slider-external [role=slider]")
      |> assert_form("#slider-external-form", [["quantity", value]])
    end

    conn = open_fixture(conn, "slider-multiple-instances")
    price = box(conn, "#slider-price")
    rating = box(conn, "#slider-rating")
    assert price["width"] >= 180 and rating["width"] >= 180
    assert rating["y"] >= price["y"] + price["height"] + 8

    conn
    |> focus(nth("#slider-price [role=slider]", 0))
    |> key("ArrowRight")
    |> assert_attribute("#slider-price", "phx-value-values", "[6,15]")
    |> assert_attribute("#slider-rating [role=slider]", "aria-valuenow", "3")
    |> assert_form("#slider-multiple-form", [["price[]", "6"], ["price[]", "15"], ["rating", "3"]])
  end

  test "disabled sliders retain submission and reject pointer keyboard and tab focus", %{
    conn: conn
  } do
    conn
    |> open_fixture("slider-disabled")
    |> assert_count("#slider-disabled [role=slider]", 2)
    |> assert_attribute(nth("#slider-disabled [role=slider]", 0), "aria-valuenow", "30")
    |> click("#slider-disabled", position: %{x: 4, y: 1})
    |> key("ArrowRight")
    |> key("End")
    |> assert_attribute(nth("#slider-disabled [role=slider]", 0), "aria-valuenow", "30")
    |> assert_attribute(nth("#slider-disabled [role=slider]", 1), "aria-valuenow", "60")
    |> key("Tab")
    |> assert_focused("#slider-disabled-form button[type=reset]")
    |> assert_form("#slider-disabled-form", [["amount[]", "30"], ["amount[]", "60"]])
  end

  test "independent collapsible disclosures hide real content and expose controls", %{conn: conn} do
    one = role("button", "One")
    two = role("button", "Two")

    conn =
      conn
      |> open_fixture("collapsible-multiple-instances")
      |> assert_attribute(one, "aria-expanded", "true")
      |> assert_visible(text("First"))
      |> assert_attribute(two, "aria-expanded", "false")
      |> assert_hidden(text("Second"))
      |> click(two)
      |> assert_attribute(two, "aria-expanded", "true")
      |> assert_visible(text("Second"))
      |> assert_visible(text("First"))

    assert_js(
      conn,
      "Array.from(document.querySelectorAll('button')).some(b => b.textContent.trim()==='Two' && b.getAttribute('aria-controls') && document.getElementById(b.getAttribute('aria-controls')).textContent.includes('Second'))"
    )

    conn
    |> focus(one)
    |> key("Space")
    |> assert_attribute(one, "aria-expanded", "false")
    |> assert_hidden(text("First"))
    |> assert_visible(text("Second"))
    |> focus(two)
    |> key("Enter")
    |> assert_attribute(two, "aria-expanded", "false")
    |> assert_hidden(text("Second"))
  end

  test "toggle group multiple selections and vertical single keyboard navigation skip disabled",
       %{conn: conn} do
    bold = role("button", "Toggle bold")
    italic = role("button", "Toggle italic")

    conn =
      conn
      |> open_fixture("toggle-group")
      |> click(bold)
      |> assert_attribute("#formatting", "phx-values", "[\"bold\"]")
      |> assert_attribute(bold, "aria-pressed", "true")
      |> click(italic)
      |> assert_attribute("#formatting", "phx-values", "[\"bold\",\"italic\"]")
      |> assert_attribute(bold, "aria-pressed", "true")
      |> assert_attribute(italic, "aria-pressed", "true")
      |> focus(italic)
      |> key("Space")
      |> assert_attribute("#formatting", "phx-values", "[\"bold\"]")
      |> assert_attribute(italic, "aria-pressed", "false")
      |> assert_attribute(bold, "aria-pressed", "true")
      |> open_fixture("toggle-group-single-vertical")
      |> assert_checked(role("radio", "Center"))
      |> assert_disabled(role("radio", "Right"))

    assert_js(
      conn,
      "(() => {const [a,b]=document.querySelectorAll('#alignment [role=radio]');const x=a.getBoundingClientRect(),y=b.getBoundingClientRect();return x.width>=24&&x.width<=80&&x.x===y.x&&y.y>=x.bottom-1;})()"
    )

    conn
    |> focus(role("radio", "Center"))
    |> key("ArrowUp")
    |> assert_focused(role("radio", "Left"))
    |> key("Space")
    |> assert_attribute("#alignment", "phx-values", "[\"left\"]")
    |> assert_checked(role("radio", "Left"))
    |> assert_checked(role("radio", "Center"), false)
    |> key("ArrowUp")
    |> assert_focused(role("radio", "Center"))
    |> assert_checked(role("radio", "Right"), false)
  end

  test "required radio shipping skips disabled and submits keyboard and pointer choices", %{
    conn: conn
  } do
    conn
    |> open_fixture("radio-group-required-vertical")
    |> assert_attribute(role("radiogroup"), "aria-required", "true")
    |> assert_checked(role("radio", "Standard"))
    |> assert_disabled(role("radio", "Express"))
    |> focus(role("radio", "Standard"))
    |> key("ArrowDown")
    |> assert_attribute("#shipping", "phx-values", "[\"overnight\"]")
    |> assert_checked(role("radio", "Overnight"))
    |> assert_focused(role("radio", "Overnight"))
    |> assert_checked(role("radio", "Standard"), false)
    |> assert_form("#shipping-form", [["shipping", "overnight"]])
    |> click_button("Submit shipping")
    |> assert_text("#shipping-form output", "Submitted shipping: overnight")
    |> click(role("radio", "Standard"))
    |> assert_attribute("#shipping", "phx-values", "[\"standard\"]")
    |> assert_checked(role("radio", "Standard"))
    |> assert_checked(role("radio", "Overnight"), false)
    |> click_button("Submit shipping")
    |> assert_text("#shipping-form output", "Submitted shipping: standard")
  end

  test "calendar leap selection navigation bounded ranges and seven-column usable grid", %{
    conn: conn
  } do
    conn =
      conn
      |> open_fixture("calendar-leap-selection")
      |> assert_count("[role=grid] thead th", 7)
      |> assert_count("[role=grid] tbody tr", 5)

    assert_js(
      conn,
      "(() => {const g=document.querySelector('[role=grid]'),rows=Array.from(g.querySelectorAll('tbody tr')),w=g.getBoundingClientRect().width,days=Array.from(rows.at(-1).querySelectorAll('td')).map(e=>e.getBoundingClientRect());return rows.every(r=>r.children.length===7)&&w>=190&&w<=500&&days.every((d,i)=>d.width>=24&&d.width<=60&&(!i||d.x>=days[i-1].right-1));})()"
    )

    conn
    |> assert_attribute("[data-day='2024-02-29']", "aria-selected", "true")
    |> click(role("button", "Wednesday, February 28th, 2024"))
    |> assert_attribute("[data-day='2024-02-28']", "aria-selected", "true")
    |> refute_attribute("[data-day='2024-02-29']", "aria-selected", "true")
    |> click_button("Go to the Next Month")
    |> assert_visible(role("grid", "March 2024"))
    |> click_button("Go to the Previous Month")
    |> assert_attribute("[data-day='2024-02-28']", "aria-selected", "true")
    |> open_fixture("calendar-bounded-range")
    |> assert_attribute(role("button", "Go to the Previous Month"), "aria-disabled", "true")
    |> assert_attribute(role("button", "Go to the Next Month"), "aria-disabled", "true")
    |> assert_disabled(role("button", "Sunday, February 4th, 2024"))
    |> assert_count("td[aria-selected=true]", 3)
    |> click(role("button", "Tuesday, February 20th, 2024"))
    |> assert_attribute("[data-day='2024-02-20']", "aria-selected", "true")
    |> assert_count("td[aria-selected=true]", 11)
  end

  test "native select labels grouped options repeated form values and resets", %{conn: conn} do
    fruit = role("combobox", "Fruit")

    conn =
      conn
      |> open_fixture("native-select-default-selection")
      |> assert_value(fruit, "pear")
      |> assert_count("optgroup[label=Fruit] option", 2)

    assert_js(
      conn,
      "(() => {const s=document.querySelector('select'),r=s.getBoundingClientRect();return r.width>=150&&r.width<=260&&r.height>=28&&r.height<=48&&s.getAttribute('aria-describedby').split(/\\s+/).map(id=>document.getElementById(id).textContent.trim()).join(' ')==='Choose a fruit.';})()"
    )

    conn
    |> select_values(fruit, "apple")
    |> assert_value(fruit, "apple")
    |> assert_form("#native-default-form", [["fruit", "apple"]])
    |> click_button(nil, "Reset", exact: true)
    |> assert_value(fruit, "pear")
    |> assert_form("#native-default-form", [["fruit", "pear"]])
    |> open_fixture("native-select-multiple-instances")
    |> select_values(role("listbox", "Colors"), ["red", "green"])
    |> select_values(role("combobox", "Shape"), "circle")
    |> assert_form("#native-multiple-form", [
      ["colors", "red"],
      ["colors", "green"],
      ["shape", "circle"]
    ])
    |> click_button(nil, "Reset", exact: true)
    |> assert_value(role("combobox", "Shape"), "square")
    |> assert_form("#native-multiple-form", [
      ["colors", "red"],
      ["colors", "blue"],
      ["shape", "square"]
    ])
  end

  test "progress caller accessibility bounded fill and indeterminate semantics", %{conn: conn} do
    conn =
      conn
      |> open_fixture("progress-custom-class-aria")
      |> assert_attribute(role("progressbar", "Upload"), "aria-valuetext", "Uploading")
      |> assert_attribute(role("progressbar"), "aria-valuemin", "0")
      |> assert_attribute(role("progressbar"), "aria-valuemax", "100")
      |> assert_attribute(role("progressbar"), "data-state", "indeterminate")
      |> assert_no_attribute(role("progressbar"), "aria-valuenow")

    assert_js(
      conn,
      "(() => {const r=document.querySelector('[role=progressbar]').getBoundingClientRect(),i=document.querySelector('[data-slot=progress-indicator]').getBoundingClientRect();return r.width>=150&&r.width<=260&&r.height>=4&&r.height<=12&&Math.abs(i.width-r.width)<0.1&&Math.abs(i.right-r.x-r.width*.75)<0.1;})()"
    )

    conn =
      conn
      |> open_fixture("progress-custom-max")
      |> assert_attribute(role("progressbar"), "aria-valuemax", "200")
      |> assert_no_attribute(role("progressbar"), "aria-valuenow")

    assert_js(
      conn,
      "(() => {const r=document.querySelector('[role=progressbar]').getBoundingClientRect(),i=document.querySelector('[data-slot=progress-indicator]').getBoundingClientRect();return Math.abs(i.right-r.x-r.width*.5)<0.1;})()"
    )

    conn
    |> open_fixture("progress-absent")
    |> assert_attribute(role("progressbar"), "data-state", "indeterminate")
    |> assert_no_attribute(role("progressbar"), "aria-valuenow")
    |> assert_js(
      "Math.abs(document.querySelector('[data-slot=progress-indicator]').getBoundingClientRect().right-document.querySelector('[role=progressbar]').getBoundingClientRect().x)<0.1"
    )
  end
end
