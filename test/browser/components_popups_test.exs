defmodule ShadcnLiveview.ComponentsPopupsBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  test "accordion single multiple disclosures keyboard and disabled boundaries", %{conn: conn} do
    intro = role("button", "Introduction")
    details = role("button", "Details")

    conn =
      conn
      |> open_fixture("accordion-closed")
      |> assert_attribute(intro, "aria-expanded", "false")
      |> click(intro)
      |> assert_text(role("region", "Introduction"), "Start with an introduction.")
      |> key("ArrowDown")
      |> assert_focused(details)
      |> key("Enter")
      |> assert_attribute(details, "aria-expanded", "true")
      |> assert_attribute(intro, "aria-expanded", "false")
      |> assert_text(role("region", "Details"), "Read the details.")
      |> click(details)
      |> assert_attribute(details, "aria-expanded", "false")
      |> assert_count(role("region"), 0)
      |> open_fixture("accordion-multiple")
      |> click(details)

    for name <- ["Introduction", "Details", "Advanced"],
        do: assert_attribute(conn, role("button", name), "aria-expanded", "true")

    conn
    |> click(intro)
    |> assert_attribute(intro, "aria-expanded", "false")
    |> assert_attribute(details, "aria-expanded", "true")
    |> open_fixture("accordion-disabled")
    |> assert_disabled(within("#accordion-disabled-demo", details))
    |> focus(within("#accordion-disabled-demo", intro))
    |> key("ArrowDown")
    |> assert_focused(within("#accordion-disabled-demo", role("button", "Advanced")))
    |> assert_js(
      "Array.from(document.querySelectorAll('#accordion-disabled-root button')).every(e=>e.disabled)"
    )
  end

  test "tabs manual activation skips disabled with one selected panel and retained focus", %{
    conn: conn
  } do
    overview = role("tab", "Overview")
    settings = role("tab", "Settings")

    conn
    |> open_fixture("tabs-disabled")
    |> assert_disabled(role("tab", "History"))
    |> focus(overview)
    |> key("ArrowRight")
    |> assert_focused(settings)
    |> assert_attribute(overview, "aria-selected", "true")
    |> assert_attribute(settings, "aria-selected", "false")
    |> key("Enter")
    |> assert_attribute(settings, "aria-selected", "true")
    |> assert_attribute(overview, "aria-selected", "false")
    |> assert_count(role("tabpanel"), 1)
    |> assert_text(role("tabpanel", "Settings"), "Adjust settings.")
    |> assert_focused(settings)
    |> key("Home")
    |> assert_focused(overview)
    |> assert_attribute(settings, "aria-selected", "true")
    |> key("Space")
    |> assert_text(role("tabpanel", "Overview"), "View the overview.")
  end

  test "alert dialog bounded confirmation cancel focus outside rejection disabled action", %{
    conn: conn
  } do
    trigger = role("button", "Delete account")
    dialog = "[role=alertdialog]"

    conn
    |> open_fixture("alert-dialog-closed")
    |> click(trigger)
    |> assert_popup(dialog, 250, 100)
    |> assert_attribute(dialog, "aria-modal", "true")
    |> assert_visible(role("alertdialog", "Are you absolutely sure?"))
    |> assert_contains(dialog, "This action cannot be undone.")
    |> assert_focused(within(dialog, role("button", "Cancel")))
    |> snapshot("alert-dialog-open.html")
    |> pointer_click(5, 5)
    |> assert_visible(dialog)
    |> click(within(dialog, role("button", "Cancel")))
    |> assert_count(dialog, 0)
    |> assert_focused(trigger)
    |> click(trigger)
    |> click(within(dialog, role("button", "Continue")))
    |> assert_count(dialog, 0)
    |> assert_focused(trigger)
    |> open_fixture("alert-dialog-small-media")
    |> assert_disabled(role("button", "Continue"))
    |> click_button("Cancel")
    |> assert_count(dialog, 0)
  end

  test "dialog accessible editor traps focus and restores trigger after escape and close", %{
    conn: conn
  } do
    trigger = role("button", "Edit profile")
    dialog = "[role=dialog]"
    save = within(dialog, role("button", "Save changes"))
    close = within(dialog, role("button", "Close"))

    conn
    |> open_fixture("dialog-closed")
    |> click(trigger)
    |> assert_popup(dialog, 250, 100)
    |> assert_visible(role("dialog", "Edit profile"))
    |> assert_attribute(dialog, "aria-modal", "true")
    |> assert_contains(dialog, "Make changes to your profile here.")
    |> assert_focused(save)
    |> snapshot("dialog-open.html")
    |> key("Shift+Tab")
    |> assert_focused(close)
    |> key("Tab")
    |> assert_focused(save)
    |> key("Escape")
    |> assert_count(dialog, 0)
    |> assert_focused(trigger)
    |> click(trigger)
    |> click(close)
    |> assert_count(dialog, 0)
    |> assert_focused(trigger)
  end

  test "drawer bottom geometry and nondismissible escape outside boundaries", %{conn: conn} do
    dialog = "[role=dialog]"
    trigger = role("button", "Open drawer")

    conn
    |> open_fixture("drawer-closed")
    |> click(trigger)
    |> assert_visible(role("dialog", "Drawer Title"))
    |> assert_popup(dialog, 250, 100)
    |> assert_contains(dialog, "Drawer Description goes here.")
    |> assert_js(
      "(() => {const r=document.querySelector('[role=dialog]').getBoundingClientRect();return Math.abs(r.bottom-innerHeight)<=1&&Math.abs(r.width-innerWidth)<=1;})()"
    )
    |> click(within(dialog, role("button", "Close drawer")))
    |> assert_count(dialog, 0)
    |> assert_focused(trigger)
    |> open_fixture("drawer-nondismissible")
    |> assert_visible(dialog)
    |> key("Escape")
    |> pointer_click(5, 5)
    |> assert_visible(dialog)
    |> click_button("Close drawer")
    |> assert_count(dialog, 0)
  end

  test "select inside a draggable drawer selects by pointer and Escape closes only the select",
       %{conn: conn} do
    drawer = role("dialog", "Drawer Title")
    trigger = role("combobox")

    conn
    |> open_fixture("drawer-select")
    |> assert_visible(drawer)
    |> click(trigger)
    |> assert_visible(role("listbox"))
    # A real pointer click: drag capture must not retarget it to the drawer.
    |> click(role("option", "Banana"))
    |> assert_count(role("listbox"), 0)
    |> assert_contains(trigger, "Banana")
    |> assert_visible(drawer)
    |> click(trigger)
    |> assert_visible(role("listbox"))
    |> key("Escape")
    |> assert_count(role("listbox"), 0)
    |> assert_visible(drawer)
    |> assert_focused(trigger)
    |> key("Escape")
    |> assert_count("[role=dialog]", 0)
  end

  test "sheet each side remains in viewport and restores trigger", %{conn: conn} do
    for side <- ["right", "left", "top", "bottom"] do
      conn = open_fixture(conn, if(side == "right", do: "sheet-closed", else: "sheet-#{side}"))
      conn = if side == "right", do: click(conn, role("button", "Edit profile")), else: conn

      conn =
        conn
        |> assert_visible(role("dialog", "Edit profile"))
        |> assert_popup("[role=dialog]", 200, 70)
        |> assert_contains("[role=dialog]", "Make changes to your profile here.")

      edge =
        case side do
          "right" -> "Math.abs(r.right-innerWidth)"
          "left" -> "Math.abs(r.x)"
          "top" -> "Math.abs(r.y)"
          "bottom" -> "Math.abs(r.bottom-innerHeight)"
        end

      conn
      |> assert_js(
        "(() => {const r=document.querySelector('[role=dialog]').getBoundingClientRect();return #{edge}<=1;})()"
      )
      |> click(
        within("[role=dialog]", role("button", if(side == "right", do: "Close", else: "Done")))
      )
      |> assert_count("[role=dialog]", 0)
      |> assert_focused(role("button", "Edit profile"))
    end
  end

  test "overlay content taller than a short viewport scrolls its last element into view", %{
    conn: conn
  } do
    overlays = [
      {"sheet-closed", "Edit profile", "sheet"},
      {"sheet-left", nil, "sheet"},
      {"sheet-bottom", nil, "sheet"},
      {"dialog-closed", "Edit profile", "dialog"},
      {"alert-dialog-closed", "Delete account", "alert-dialog"},
      {"drawer-closed", "Open drawer", "drawer"},
      {"drawer-right", nil, "drawer"}
    ]

    for {width, height} <- [{390, 600}, {1280, 600}], {fixture, trigger, slot} <- overlays do
      content = "[data-slot=#{slot}-content]"
      # The footer when the fixture has one, else an end marker appended after the header.
      target = "#{content} [data-overflow-target]"

      conn = conn |> viewport(width, height) |> open_fixture(fixture)
      conn = if trigger, do: click(conn, role("button", trigger)), else: conn

      conn
      |> assert_visible(content)
      # Tall app content pushes the last element past the viewport bottom.
      |> assert_js("""
      (() => {
        const c = document.querySelector(#{Jason.encode!(content)});
        let t = c.querySelector('[data-overflow-target]');
        if (!t) {
          t = c.querySelector('[data-slot=#{slot}-footer]');
          if (!t) { t = document.createElement('p'); t.textContent = 'End of content'; c.append(t); }
          t.dataset.overflowTarget = '';
          const tall = document.createElement('div');
          tall.style.cssText = 'height:1200px;flex:none';
          t.before(tall);
        }
        return t.getBoundingClientRect().top > innerHeight;
      })()
      """)
      |> assert_js(
        "(() => {const c=document.querySelector(#{Jason.encode!(content)}).getBoundingClientRect();return c.top>=-1&&c.bottom<=innerHeight+1;})()"
      )
      |> then(fn conn ->
        %{"x" => x, "y" => y, "width" => w, "height" => h} = box(conn, content)
        conn |> move(x + w / 2, y + h / 2) |> wheel(0, 3000)
      end)
      |> assert_js(
        "(() => {const r=document.querySelector(#{Jason.encode!(target)}).getBoundingClientRect();return r.height>0&&r.top>=0&&r.bottom<=innerHeight+1;})()"
      )
    end
  end

  test "popover editable disclosure focuses field and dismisses escape outside", %{conn: conn} do
    trigger = role("button", "Edit")

    conn
    |> open_fixture("popover-closed")
    |> click(trigger)
    |> assert_popup("[role=dialog]", 200, 40)
    |> assert_focused(role("textbox", "Name"))
    |> fill(role("textbox", "Name"), "Grace")
    |> assert_value(role("textbox", "Name"), "Grace")
    |> key("Escape")
    |> assert_count(role("dialog"), 0)
    |> assert_focused(trigger)
    |> click(trigger)
    |> assert_visible(role("dialog"))
    |> pointer_click(5, 500)
    |> assert_count(role("dialog"), 0)
    |> assert_attribute(trigger, "aria-expanded", "false")
  end

  test "hover card pointer and keyboard disclose without stealing focus", %{conn: conn} do
    trigger = role("link", "Profile")

    conn
    |> open_fixture("hover-card-closed")
    |> hover(trigger)
    |> assert_text("#hover-closed-content", "Profile details")
    |> assert_popup("#hover-closed-content", 180, 30)
    |> hover("#hover-closed-content")
    |> assert_visible("#hover-closed-content")
    |> move(5, 500)
    |> assert_count("#hover-closed-content", 0)
    |> focus(trigger)
    |> assert_visible("#hover-closed-content")
    |> assert_focused(trigger)
    |> key("Escape")
    |> assert_count("#hover-closed-content", 0)
    |> assert_focused(trigger)
  end

  test "tooltip associates description and hover focus escape dismissals", %{conn: conn} do
    trigger = role("button", "Hover")

    conn
    |> open_fixture("tooltip")
    |> assert_text(role("tooltip"), "Add to library")
    |> assert_popup("[role=tooltip]", 70, 20)
    |> assert_js(
      "document.querySelector('button').getAttribute('aria-describedby')===document.querySelector('[role=tooltip]').id"
    )
    |> key("Escape")
    |> assert_count(role("tooltip"), 0)
    |> hover(trigger)
    |> assert_visible(role("tooltip"))
    |> move(5, 500)
    |> assert_count(role("tooltip"), 0)
    |> blur(trigger)
    |> focus(trigger)
    |> assert_visible(role("tooltip"))
    |> assert_focused(trigger)
    |> key("Escape")
    |> assert_count(role("tooltip"), 0)
  end

  test "context menu real right click keyboard invocation action dismissal disabled", %{
    conn: conn
  } do
    conn
    |> open_fixture("context-menu")
    |> click("#context-demo-trigger", button: "right", position: %{x: 40, y: 40})
    |> assert_popup("[role=menu]", 100, 70)
    # Radix: a pointer open focuses the menu itself; arrows then enter the items.
    |> assert_focused("[role=menu]")
    |> assert_count("[role=menuitem][data-highlighted]", 0)
    |> key("ArrowDown")
    |> assert_focused(role("menuitem", "Back"))
    |> key("ArrowDown")
    |> assert_focused(role("menuitem", "Forward"))
    |> key("Enter")
    |> assert_count(role("menu"), 0)
    |> assert_focused("#context-demo-trigger")
    |> key("Shift+F10")
    |> assert_visible(role("menu"))
    |> assert_focused(role("menuitem", "Back"))
    |> key("End")
    |> assert_focused(role("menuitem", "Reload"))
    |> key("Escape")
    |> assert_count(role("menu"), 0)
    |> assert_focused("#context-demo-trigger")
    |> open_fixture("context-menu-disabled")
    |> click("#context-disabled-trigger", button: "right")
    |> assert_count(role("menu"), 0)
  end

  test "dropdown checkbox radio persist after dismissal and reopening", %{conn: conn} do
    trigger = role("button", "Preferences")

    conn
    |> open_fixture("dropdown-menu-checks")
    |> assert_popup("[role=menu]", 100, 70)
    |> click(role("menuitemcheckbox", "Show status"))
    |> assert_count(role("menu"), 0)
    |> assert_focused(trigger)
    |> click(trigger)
    |> assert_attribute(role("menuitemcheckbox", "Show status"), "aria-checked", "false")
    |> click(role("menuitemradio", "Comfortable"))
    |> assert_count(role("menu"), 0)
    |> focus(trigger)
    |> key("ArrowDown")
    |> assert_attribute(role("menuitemradio", "Comfortable"), "aria-checked", "true")
    |> assert_attribute(role("menuitemradio", "Compact"), "aria-checked", "false")
    |> key("Home")
    |> assert_focused(role("menuitemcheckbox", "Show status"))
    |> key("Escape")
    |> assert_count(role("menu"), 0)
    |> assert_focused(trigger)
  end

  test "menubar arrow switches open menus and action restores trigger focus", %{conn: conn} do
    file = role("menuitem", "File")
    edit = role("menuitem", "Edit")
    undo = role("menuitem", "Undo")

    conn
    |> open_fixture("menubar-default-open")
    |> assert_attribute(file, "aria-expanded", "true")
    |> assert_attribute(role("menuitem", "Unavailable"), "aria-disabled", "true")
    |> assert_popup("[role=menu]", 100, 90)
    |> focus(file)
    |> key("ArrowRight")
    |> assert_focused(edit)
    |> assert_attribute(edit, "aria-expanded", "true")
    |> assert_attribute(file, "aria-expanded", "false")
    |> assert_visible(undo)
    |> assert_focused(edit)
    |> key("ArrowDown")
    |> assert_focused(undo)
    |> key("Enter")
    |> assert_count(role("menu"), 0)
    |> assert_focused(edit)
    |> key("ArrowDown")
    |> assert_focused(undo)
    |> key("Escape")
    |> assert_count(role("menu"), 0)
    |> assert_focused(edit)
  end

  test "navigation disclosures switch content and escape restores focus", %{conn: conn} do
    docs = role("button", "Docs")
    about = role("button", "About")

    conn
    |> open_fixture("navigation-viewport-closed")
    |> click(docs)
    |> assert_attribute(docs, "aria-expanded", "true")
    |> assert_attribute(role("link", "Guide"), "href", "/docs")
    |> assert_popup("[data-slot=navigation-menu-content]", 40, 25)
    |> click(about)
    |> assert_attribute(about, "aria-expanded", "true")
    |> assert_attribute(docs, "aria-expanded", "false")
    |> assert_count(role("link", "Guide"), 0)
    |> assert_attribute(role("link", "Company"), "href", "/about")
    |> key("ArrowDown")
    |> assert_focused(role("link", "Company"))
    |> key("Escape")
    |> assert_attribute(about, "aria-expanded", "false")
    |> assert_focused(about)
    |> assert_count(role("link", "Company"), 0)
  end

  test "select keyboard updates label native value and leaves disabled instance untouched", %{
    conn: conn
  } do
    trigger = "#select-closed-0-trigger"

    conn
    |> open_fixture("select-closed-multiple")
    |> assert_disabled("#select-closed-1-trigger")
    |> focus(trigger)
    |> key("ArrowDown")
    |> assert_popup("[role=listbox]", 70, 50)
    |> assert_focused(role("option", "Apple"))
    |> key("End")
    |> assert_focused(role("option", "Banana"))
    |> key("Enter")
    |> assert_count(role("listbox"), 0)
    |> assert_text(trigger, "Banana")
    |> assert_value("select[name=fruit-0]", "banana")
    |> assert_focused(trigger)
    |> assert_text("#select-closed-1-trigger", "Fruit")
    |> click(trigger)
    |> assert_attribute(role("option", "Banana"), "data-state", "checked")
    |> key("Home")
    |> key("Enter")
    |> assert_text(trigger, "Apple")
    |> assert_value("select[name=fruit-0]", "apple")
  end

  test "command filtering no-results keyboard active descendant and server activation", %{
    conn: conn
  } do
    input = role("combobox")

    conn
    |> open_fixture("command")
    |> assert_visible(role("option", "Calendar"))
    |> assert_visible(role("option", "Search Emoji"))
    |> fill(input, "unmatchedxyz")
    |> assert_visible(text("No results found."))
    |> assert_count(role("option"), 0)
    |> fill(input, "emoji")
    |> assert_visible(role("option", "Search Emoji"))
    |> assert_count(role("option", "Calendar"), 0)
    |> assert_hidden(text("No results found."))
    |> key("ArrowDown")
    |> assert_js(
      "document.querySelector('[role=combobox]').getAttribute('aria-activedescendant')===Array.from(document.querySelectorAll('[role=option]')).find(e=>e.textContent.trim()==='Search Emoji').id"
    )
    |> key("Enter")
    |> assert_text(role("status"), "Selected command: emoji")
    |> assert_focused(input)
    |> fill(input, "")
    |> key("Home")
    |> key("Enter")
    |> assert_text(role("status"), "Selected command: calendar")
  end

  test "combobox search selection submission clear and disabled boundaries", %{conn: conn} do
    input = role("combobox")

    conn
    |> open_fixture("combobox")
    |> fill(input, "no-such-framework")
    |> assert_visible(text("No frameworks found."))
    |> assert_count(role("option"), 0)
    |> fill(input, "pho")
    |> assert_visible(role("option", "Phoenix"))
    |> assert_count(role("option", "Next.js"), 0)
    |> assert_popup("[data-slot=combobox-content]", 100, 30)
    |> key("ArrowDown")
    |> key("Enter")
    |> assert_value(input, "Phoenix")
    |> assert_attribute(input, "aria-expanded", "false")
    |> assert_focused(input)
    |> click_button("Submit framework")
    |> assert_text(role("status"), "Submitted framework: phoenix")
    |> open_fixture("combobox-value")
    |> assert_value(input, "Phoenix")
    |> click("[data-slot=combobox-clear]")
    |> assert_value(input, "")
    |> click_button("Submit framework")
    |> assert_text(role("status"), "Submitted framework: None")
    |> open_fixture("combobox-disabled")
    |> assert_disabled(input)
    |> assert_value(input, "Next.js")
  end

  test "OTP rejects partial and non-digits truncates complete values and repaints server slots",
       %{conn: conn} do
    slots = "[data-slot=input-otp-slot]"
    conn = conn |> open_fixture("input-otp") |> assert_count(slots, 4)

    for index <- 0..3 do
      assert_popup(conn, "#{slots}:nth-child(#{index + 1})", 20, 20)
    end

    conn
    |> fill("#otp-demo", "12")
    |> assert_js(
      "JSON.stringify(Array.from(document.querySelectorAll('[data-slot=input-otp-slot]')).map(e=>e.textContent))===JSON.stringify(['1','2','',''])"
    )
    |> fill("#otp-demo", "abcd")
    |> assert_value("#otp-demo", "12")
    |> assert_js(
      "JSON.stringify(Array.from(document.querySelectorAll('[data-slot=input-otp-slot]')).map(e=>e.textContent))===JSON.stringify(['1','2','',''])"
    )
    |> click_button("Submit code")
    |> assert_focused("#otp-demo")
    |> assert_js("!document.querySelector('#otp-demo').checkValidity()")
    |> assert_count(role("status"), 0)
    |> fill("#otp-demo", "12345")
    |> assert_value("#otp-demo", "1234")
    |> assert_js(
      "JSON.stringify(Array.from(document.querySelectorAll('[data-slot=input-otp-slot]')).map(e=>e.textContent))===JSON.stringify(['1','2','3','4'])"
    )
    |> click_button("Submit code")
    |> assert_text(role("status"), "Submitted code: 1234")
    |> click_button("Set server code to 9021")
    |> assert_value("#otp-demo", "9021")
    |> assert_js(
      "JSON.stringify(Array.from(document.querySelectorAll('[data-slot=input-otp-slot]')).map(e=>e.textContent))===JSON.stringify(['9','0','2','1'])"
    )
    |> click_button("Submit code")
    |> assert_text(role("status"), "Submitted code: 9021")
    |> open_fixture("input-otp-disabled")
    |> assert_disabled("#disabled-otp")
    |> assert_js(
      "JSON.stringify(Array.from(document.querySelectorAll('[data-slot=input-otp-slot]')).map(e=>e.textContent))===JSON.stringify(['9','8','7','6'])"
    )
  end
end
