defmodule ShadcnLiveview.ComponentsLayoutBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: [click_button: 4]
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  test "vertical carousel keyboard pointer slide visibility and end boundaries", %{conn: conn} do
    root = "#carousel-vertical-demo"
    previous = within(root, role("button", "Previous slide"))
    next = within(root, role("button", "Next slide"))

    conn =
      conn
      |> open_fixture("carousel-vertical")
      |> assert_disabled(previous)
      |> assert_enabled(next)
      |> assert_count(root <> " [aria-roledescription=slide]", 3)

    bounds = box(conn, root <> " [data-slot=carousel-content]")
    assert bounds["width"] > 200 and bounds["height"] > 150 and bounds["height"] < 220

    conn =
      conn
      |> click(next)
      |> assert_attribute(root, "phx-value-start-index", "1")
      |> assert_enabled(previous)
      |> focus(previous)
      |> key("ArrowRight")
      |> assert_attribute(root, "phx-value-start-index", "2")
      |> assert_disabled(next)
      |> assert_focused(previous)
      |> assert_js(
        "(() => {const v=document.querySelector('#carousel-vertical-demo [data-slot=carousel-content]').getBoundingClientRect(),s=document.querySelectorAll('#carousel-vertical-demo [aria-roledescription=slide]')[2].getBoundingClientRect();return Math.abs(s.bottom-v.bottom)<1;})()"
      )
      |> key("ArrowRight")
      |> assert_attribute(root, "phx-value-start-index", "2")

    conn
    |> drag_pointer(
      {bounds["x"] + bounds["width"] / 2, bounds["y"] + 25},
      {bounds["x"] + bounds["width"] / 2, bounds["y"] + bounds["height"] - 20}
    )
    |> assert_attribute(root, "phx-value-start-index", "1")
    |> assert_enabled(next)
    |> assert_js(
      "(() => {const v=document.querySelector('#carousel-vertical-demo [data-slot=carousel-content]').getBoundingClientRect(),s=document.querySelectorAll('#carousel-vertical-demo [aria-roledescription=slide]')[1].getBoundingClientRect();return Math.abs(s.bottom-v.bottom)<1;})()"
    )
  end

  test "resizable pointer keyboard geometry constraints and disabled handle", %{conn: conn} do
    conn =
      conn
      |> open_fixture("resizable-vertical")
      |> assert_attribute(role("separator"), "aria-orientation", "horizontal")
      |> assert_attribute(role("separator"), "aria-controls", "resizable-vertical-one")
      |> assert_attribute(role("separator"), "aria-valuenow", "30")

    initial = box(conn, "#resizable-vertical-one")
    group = box(conn, "#resizable-vertical-demo")
    handle = box(conn, "[role=separator]")
    assert group["height"] >= 256 and group["width"] > 250

    conn =
      conn
      |> drag_pointer(
        {handle["x"] + handle["width"] / 2, handle["y"] + handle["height"] / 2},
        {handle["x"] + handle["width"] / 2, handle["y"] + 50},
        10
      )
      |> assert_js(
        "Number(document.querySelector('[role=separator]').getAttribute('aria-valuenow'))>45"
      )
      |> assert_attribute(
        "#resizable-vertical-demo",
        "phx-value-layout",
        ~r/resizable-vertical-one/
      )

    assert box(conn, "#resizable-vertical-one")["height"] > initial["height"] + 40

    conn =
      conn
      |> focus(role("separator"))
      |> key("End")
      |> assert_attribute(role("separator"), "aria-valuenow", "80")
      |> assert_js(
        "Math.abs(JSON.parse(document.querySelector('#resizable-vertical-demo').getAttribute('phx-value-layout'))['resizable-vertical-one']-80)<0.5"
      )

    large = box(conn, "#resizable-vertical-one")
    small = box(conn, "#resizable-vertical-two")
    assert_in_delta large["height"] / (large["height"] + small["height"]), 0.8, 0.005
    assert_in_delta small["y"], large["y"] + large["height"] + handle["height"], 0.5
    assert_in_delta large["height"] + small["height"] + handle["height"], group["height"] - 2, 0.5

    conn =
      conn
      |> key("Home")
      |> assert_attribute(role("separator"), "aria-valuenow", "10")
      |> key("ArrowDown")
      |> assert_attribute(role("separator"), "aria-valuenow", "15")
      |> assert_focused(role("separator"))
      |> open_fixture("resizable-multiple")
      |> assert_attribute("#resize-fixed-h", "aria-disabled", "true")

    width = box(conn, "#resize-fixed-a")["width"]
    handle = box(conn, "#resize-fixed-h")

    conn =
      drag_pointer(
        conn,
        {handle["x"] + handle["width"] / 2, handle["y"] + handle["height"] / 2},
        {handle["x"] + 40, handle["y"] + handle["height"] / 2},
        8
      )

    assert_in_delta box(conn, "#resize-fixed-a")["width"], width, 0.05
  end

  test "sidebar desktop shortcut and mobile modal resize navigation restore focus and scrolling",
       %{conn: conn} do
    trigger = "[data-slot=sidebar-trigger]"

    conn =
      conn
      |> viewport(1100, 800)
      |> open_fixture("sidebar-collapsed-icon")
      |> assert_attribute(trigger, "aria-expanded", "false")
      |> assert_hidden(within("#sidebar-icon-panel", role("link", "Details")))

    width = box(conn, "#sidebar-icon-panel")["width"]
    assert width > 40 and width < 100

    conn =
      conn
      |> click(trigger)
      |> assert_attribute("#sidebar-icon", "phx-value-open", "true")
      |> assert_attribute(trigger, "aria-expanded", "true")
      |> assert_js(
        "document.querySelector('#sidebar-icon-panel').getBoundingClientRect().width>250"
      )
      |> assert_visible(within("#sidebar-icon-panel", role("link", "Details")))

    bounds = box(conn, "#sidebar-icon-panel")
    assert_in_delta bounds["x"] + bounds["width"], 1100, 0.5
    assert bounds["height"] == 800

    conn =
      conn
      |> focus(trigger)
      |> key("Control+b")
      |> assert_attribute("#sidebar-icon", "phx-value-open", "false")
      |> assert_js(
        "document.querySelector('#sidebar-icon-panel').getBoundingClientRect().width<100"
      )
      |> viewport(390, 700)
      |> assert_attribute(trigger, "aria-expanded", "false")
      |> click(trigger)
      |> assert_visible(role("dialog", "Sidebar"))
      |> assert_attribute(role("dialog", "Sidebar"), "aria-modal", "true")
      |> assert_attribute("#sidebar-icon", "phx-value-mobile-open", "true")
      |> assert_js(
        "(() => {const r=document.querySelector('[role=dialog]').getBoundingClientRect();return r.width>240&&r.width<=358&&Math.abs(r.right-390)<0.5;})()"
      )
      |> assert_focused(role("dialog", "Sidebar"))
      |> snapshot("sidebar-mobile-open.html")
      |> key("Tab")
      |> assert_focused(within(role("dialog"), role("button", "Overview")))
      |> key("Escape")
      |> assert_hidden(role("dialog", "Sidebar"))
      |> assert_attribute("#sidebar-icon", "phx-value-mobile-open", "false")
      |> assert_focused(trigger)

    assert_js(conn, "document.body.style.overflow !== 'hidden'")
  end

  test "mobile sidebar popups keep focus across patches and own Escape before the sheet",
       %{conn: conn} do
    trigger = "[data-slot=sidebar-trigger]"
    sheet = role("dialog", "Sidebar")
    team = role("button", "Team")
    acme = role("menuitem", "Acme")

    backdrop =
      "[...document.querySelector('#sidebar-popup').children].find(node => node.matches('.fixed.inset-0'))"

    conn
    |> viewport(1100, 800)
    |> open_fixture("sidebar-menu-popup")
    |> assert_attribute(trigger, "aria-expanded", "true")
    # Upstream's trigger has no expanded state: its ghost button stays neutral when expanded.
    |> assert_js(
      "getComputedStyle(document.querySelector('[data-slot=sidebar-trigger]')).backgroundColor === 'rgba(0, 0, 0, 0)'"
    )
    |> viewport(390, 700)
    |> click(trigger)
    |> assert_visible(sheet)
    |> assert_focused(sheet)
    # The Sheet overlay upstream: 10% black with a small backdrop blur.
    |> assert_js(
      "(() => {const s=getComputedStyle(#{backdrop});return /(\\/ |, )0\\.1\\)$/.test(s.backgroundColor)&&s.backdropFilter.includes('blur');})()"
    )
    |> click(team)
    |> assert_visible(role("menu"))
    # Radix: a pointer open focuses the menu itself, not its first item.
    |> assert_focused("[role=menu]")
    |> assert_count("[role=menuitem][data-highlighted]", 0)
    |> PhoenixTest.Playwright.evaluate(
      "liveSocket.execJS(document.getElementById('sidebar-popup-ticks'), JSON.stringify([['push', {event: 'preview:increment', value: {id: 'sidebar-popup-ticks'}}]]))"
    )
    |> assert_text("#sidebar-popup-ticks", "1")
    |> assert_visible(role("menu"))
    |> assert_focused("[role=menu]")
    |> key("ArrowDown")
    |> assert_focused(acme)
    |> key("Escape")
    |> assert_count(role("menu"), 0)
    |> assert_visible(sheet)
    |> assert_attribute("#sidebar-popup", "phx-value-mobile-open", "true")
    |> assert_focused(team)
    |> key("Escape")
    |> assert_hidden(sheet)
    |> assert_attribute("#sidebar-popup", "phx-value-mobile-open", "false")
    |> assert_focused(trigger)
  end

  test "collapsed desktop offcanvas sidebar leaves the tab order and accessibility tree",
       %{conn: conn} do
    trigger = "[data-slot=sidebar-trigger]"
    panel = "#sidebar-offcanvas-panel"
    details = within(panel, role("link", "Details"))

    # Every sidebar control except the edge rail: inert nodes refuse programmatic focus.
    focusable =
      "[...document.querySelectorAll('#{panel} a[href], #{panel} button:not([data-sidebar=rail])')]" <>
        ".filter(node => {node.focus(); return document.activeElement === node;}).length"

    collapsed = fn conn ->
      conn
      |> assert_attribute(trigger, "aria-expanded", "false")
      |> assert_js(
        "['header', 'content', 'footer'].every(slot => document.querySelector('#{panel} [data-slot=sidebar-' + slot + ']').closest('[inert]'))"
      )
      # inert drops the subtree from the accessibility tree; Playwright role queries ignore inert.
      |> assert_js("!!document.querySelector('#{panel} a[href=\"#details\"]').closest('[inert]')")
      |> assert_js("#{focusable} === 0")
      |> assert_js("!document.querySelector('#{panel} [data-sidebar=rail]').closest('[inert]')")
      |> focus(trigger)
      |> key("Shift+Tab")
      |> assert_js("!document.querySelector('#{panel}').contains(document.activeElement)")
      |> focus(trigger)
      |> key("Tab")
      |> assert_js("!document.querySelector('#{panel}').contains(document.activeElement)")
    end

    conn =
      conn
      |> viewport(1280, 800)
      |> open_fixture("sidebar-collapsed-offcanvas")
      |> collapsed.()
      |> click(trigger)
      |> assert_attribute("#sidebar-offcanvas", "phx-value-open", "true")
      |> assert_attribute(trigger, "aria-expanded", "true")
      |> assert_js("!document.querySelector('#{panel} [inert]')")
      |> assert_visible(details)
      |> assert_js("#{focusable} === 2")
      |> focus(details)
      |> key("Control+b")
      |> assert_attribute("#sidebar-offcanvas", "phx-value-open", "false")
      |> assert_focused(trigger)
      |> collapsed.()
      |> key("Meta+b")
      |> assert_attribute("#sidebar-offcanvas", "phx-value-open", "true")
      |> assert_js("!document.querySelector('#{panel} [inert]')")
      |> key("Meta+b")
      |> assert_attribute("#sidebar-offcanvas", "phx-value-open", "false")
      |> collapsed.()
      |> viewport(390, 700)
      |> assert_js("!document.querySelector('#{panel} [inert]')")
      |> click(trigger)
      |> assert_visible(role("dialog", "Sidebar"))
      |> assert_focused(role("dialog", "Sidebar"))
      |> key("Tab")
      |> assert_focused(within(role("dialog"), role("button", "Overview")))
      |> assert_visible(within(role("dialog"), role("link", "Details")))
      |> key("Escape")
      |> assert_hidden(role("dialog", "Sidebar"))
      |> assert_focused(trigger)
      |> viewport(1280, 800)

    collapsed.(conn)
  end

  test "chart signed series geometry keyboard tooltip and server data patches", %{conn: conn} do
    chart = within("#sales-bars-canvas", role("application", "Monthly desktop and mobile sales"))
    tooltip = "#sales-bars-canvas .recharts-tooltip-wrapper"

    conn =
      conn
      |> open_fixture("chart-bar-series")
      |> assert_visible(chart)
      |> assert_count("#sales-bars-canvas .recharts-bar-rectangles path", 6)
      |> assert_js(
        "Array.from(document.querySelectorAll('#sales-bars-canvas .recharts-bar-rectangles path')).every(e=>e.getBBox().width>5&&e.getBBox().height>5)"
      )

    assert_js(
      conn,
      "(() => {const r=document.querySelector('#sales-bars-canvas [role=application]').getBoundingClientRect(),b=Array.from(document.querySelectorAll('#sales-bars-canvas .recharts-bar-rectangles path')).map(e=>e.getBBox());return r.width>250&&r.height===240&&b[1].height>b[0].height&&Math.abs(b[2].y-b[0].y-b[0].height)<.5&&b.every(x=>x.x>=0&&x.x+x.width<=r.width&&x.y>=0&&x.y+x.height<=r.height);})()"
    )

    conn =
      conn
      |> focus(chart)
      |> assert_visible(tooltip)
      |> assert_contains(tooltip, "January")
      |> assert_contains(tooltip, "186")
      |> key("ArrowRight")
      |> assert_contains(tooltip, "February")
      |> assert_contains(tooltip, "305")
      |> key("ArrowRight")
      |> assert_contains(tooltip, "March")
      |> assert_contains(tooltip, "-45")
      |> key("ArrowRight")
      |> assert_contains(tooltip, "April")
      |> assert_count(within(tooltip, text("0")), 2)
      |> key("Escape")
      |> assert_hidden(tooltip)
      |> click_button("Change chart data")
      |> assert_contains("#sales-bars-canvas", "May")
      |> assert_contains("#sales-bars-canvas", "June")
      |> assert_js(
        "!document.querySelector('#sales-bars-canvas').textContent.includes('January')"
      )
      |> assert_count("#sales-bars-canvas .recharts-bar-rectangles path", 4)
      |> focus(chart)
      |> assert_contains(tooltip, "May")
      |> assert_contains(tooltip, "300")
      |> key("ArrowRight")
      |> assert_contains(tooltip, "June")
      |> assert_contains(tooltip, "-30")

    connected(conn)
  end

  test "message scroller follows appended latest but preserves earlier readers", %{conn: conn} do
    viewport = "#stream-end [data-slot=message-scroller-viewport]"

    conn =
      conn
      |> open_fixture("message-scroller-end")
      |> click_button(nil, "Append messages", exact: true)
      |> assert_visible(within("#stream-end", text("Added message 8")))
      |> assert_count("#stream-end [data-slot=message-scroller-item]", 8)
      |> assert_js(
        "(() => {const e=document.querySelector('#{viewport}');return e.scrollHeight-e.clientHeight-e.scrollTop<=1&&e.clientHeight>80&&e.clientHeight<170&&e.scrollHeight>e.clientHeight*3;})()"
      )
      |> click(within("#stream-end", role("button", "Earlier")))
      |> assert_js("document.querySelector('#{viewport}').scrollTop<=1")
      |> click_button(nil, "Append more", exact: true)
      |> assert_count("#stream-end [data-slot=message-scroller-item]", 12)
      |> assert_js("document.querySelector('#{viewport}').scrollTop<=1")
      |> assert_visible(within("#stream-end", text("First message")))
      |> click(within("#stream-end", role("button", "Latest")))
      |> assert_js(
        "(() => {const e=document.querySelector('#{viewport}');return e.scrollHeight-e.clientHeight-e.scrollTop<=1;})()"
      )

    assert_js(
      conn,
      "(() => {const v=document.querySelector('#{viewport}').getBoundingClientRect(),last=Array.from(document.querySelectorAll('#stream-end [data-slot=message-scroller-item]')).at(-1).getBoundingClientRect();return last.y>=v.y&&last.bottom<=v.bottom+1;})()"
    )
  end

  test "sidebar's last element stays inside the viewport even when svh over-reports", %{
    conn: conn
  } do
    # Embedded WebKit views can report 100svh taller than the visible viewport. The fixed
    # container cannot scroll, so an oversized panel hides its footer below the fold. Inflate
    # the container's height to that failure size and require it to stay in the viewport.
    conn
    |> open_fixture("sidebar")
    |> assert_js(
      "(() => {const c=document.querySelector('[data-slot=sidebar-container]'),last=c.querySelector('[data-slot=sidebar-inner]').lastElementChild,h=document.documentElement.clientHeight;c.style.height='calc(100svh + 240px)';const b=c.getBoundingClientRect(),lb=last.getBoundingClientRect();c.style.height='';return getComputedStyle(c).position==='fixed'&&b.bottom<=h+0.5&&lb.top>=0&&lb.bottom<=h+0.5;})()"
    )
  end

  test "questionnaire validation keyboard answers back navigation and submission", %{conn: conn} do
    progress = "#questionnaire-flow [data-slot=questionnaire-progress]"

    conn
    |> open_fixture("questionnaire-flow")
    |> assert_text(progress, "Question 1 of 2")
    |> assert_disabled(role("radio", "Unavailable"))
    |> click_button(nil, "Next", exact: true)
    |> assert_attribute(
      "[data-slot=questionnaire-item][phx-value-name=rating]",
      "aria-invalid",
      "true"
    )
    |> assert_text(role("alert"), "Choose an answer to continue.")
    |> assert_text(progress, "Question 1 of 2")
    |> snapshot("questionnaire-invalid.html")
    |> key("b")
    |> assert_checked(role("radio", "Great"))
    |> assert_count(role("alert"), 0)
    |> click_button(nil, "Next", exact: true)
    |> assert_text(progress, "Question 2 of 2")
    |> assert_hidden("[data-slot=questionnaire-item][phx-value-name=rating]")
    |> fill(role("textbox", "Your feedback"), "Excellent visit")
    |> click_button(nil, "Previous", exact: true)
    |> assert_checked(role("radio", "Great"))
    |> click_button(nil, "Next", exact: true)
    |> assert_value(role("textbox", "Your feedback"), "Excellent visit")
    |> click_button(nil, "Submit", exact: true)
    |> assert_contains("output", "Submitted answers:")
    |> assert_js(
      "JSON.stringify(JSON.parse(document.querySelector('output').innerText.replace('Submitted answers: ','')))===JSON.stringify({rating:['great'],comment:['Excellent visit']})"
    )
    |> assert_hidden(text("Archived question"))
  end

  test "scroll area wheel and keyboard scroll bounded content without scrolling page", %{
    conn: conn
  } do
    viewport = "#scroll-area-demo [data-slot=scroll-area-viewport]"
    conn = conn |> open_fixture("scroll-area") |> assert_attribute(viewport, "tabindex", "0")

    assert_js(
      conn,
      "(() => {const r=document.querySelector('#scroll-area-demo').getBoundingClientRect(),e=document.querySelector('#{viewport}'),v=e.getBoundingClientRect();return r.width===192&&r.height===128&&v.width>100&&v.height>60&&v.x>=r.x&&v.bottom<=r.bottom&&e.scrollHeight>v.height*3;})()"
    )

    page_top = value(conn, "window.scrollY")

    conn =
      conn
      |> hover(viewport)
      |> wheel(0, 180)
      |> assert_js("document.querySelector('#{viewport}').scrollTop>100")
      |> focus(viewport)
      |> key("End")
      |> assert_js(
        "(() => {const e=document.querySelector('#{viewport}');return e.scrollHeight-e.clientHeight-e.scrollTop<=1;})()",
        stable_frames: 3
      )

    assert_js(
      conn,
      "(() => {const v=document.querySelector('#{viewport}').getBoundingClientRect(),l=Array.from(document.querySelectorAll('#scroll-area-demo *')).find(e=>e.textContent==='Item 20').getBoundingClientRect();return l.y>=v.y&&l.bottom<=v.bottom+1;})()"
    )

    conn
    |> key("Home")
    |> assert_js("document.querySelector('#{viewport}').scrollTop<=1", stable_frames: 3)
    |> assert_js("window.scrollY===#{page_top}")
    |> assert_focused(viewport)
  end
end
