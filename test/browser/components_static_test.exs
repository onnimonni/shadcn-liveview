defmodule ShadcnLiveview.ComponentsStaticBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import ShadcnLiveview.BrowserHelpers
  alias PhoenixTest.Playwright, as: Browser
  alias PlaywrightEx.{BrowserContext, Page}
  @moduletag :browser_test

  @examples [
    {"alert", "[role=alert]"},
    {"aspect-ratio", "[data-slot=aspect-ratio]"},
    {"attachment", "[data-slot=attachment]"},
    {"avatar", "[data-slot=avatar]"},
    {"badge", "[data-slot=badge]"},
    {"breadcrumb", "nav[aria-label=breadcrumb]"},
    {"bubble", "[data-slot=bubble]"},
    {"button-group", "[data-slot=button-group]"},
    {"card", "[data-slot=card]"},
    {"direction", "#fixture-stage .p-2"},
    {"empty", "[data-slot=empty]"},
    {"item", "[data-slot=item]"},
    {"kbd", "kbd"},
    {"marker", "[data-slot=marker]"},
    {"message", "[data-slot=message]"},
    {"separator", "[data-slot=separator]"},
    {"skeleton", "[data-slot=skeleton]"},
    {"spinner", "[role=status]"},
    {"table", "table"}
  ]

  for {family, selector} <- @examples do
    test "#{family} preserves usable layout and React reference geometry", %{conn: conn} do
      family = unquote(family)
      selector = unquote(selector)
      conn = open_fixture(conn, family)
      assert {:ok, page} = BrowserContext.new_page(conn.context_id, timeout: 5_000)
      reference = Map.merge(conn, %{page_id: page.guid, frame_id: page.main_frame.guid})

      try do
        reference = visit(reference, "/preview/react-fixture.html?fixture=#{URI.encode(family)}")

        for session <- [conn, reference] do
          Browser.evaluate(session, "document.fonts.ready")

          Browser.evaluate(
            session,
            "(() => {const style=document.createElement('style');style.textContent='*,*::before,*::after{animation:none!important;transition:none!important}';document.head.append(style);})()"
          )
        end

        assert_inside_stage(conn, selector)
        assert_visible(reference, selector)
        actual = box(conn, selector)
        expected = box(reference, selector)
        assert_in_delta actual["width"], expected["width"], 0.5
        assert_in_delta actual["height"], expected["height"], 0.5

        if family == "aspect-ratio",
          do: assert_in_delta(actual["width"] / actual["height"], 16 / 9, 0.0005)

        if family == "table" do
          assert_js(
            conn,
            "(() => {const h=Array.from(document.querySelectorAll('th')),c=Array.from(document.querySelectorAll('tbody tr td'));return h.length===c.length&&h.every((e,i)=>{const a=e.getBoundingClientRect(),b=c[i].getBoundingClientRect();return Math.abs(a.x-b.x)<.5&&Math.abs(a.width-b.width)<.5;});})()"
          )
        end
      after
        assert {:ok, _} = Page.close(page.guid, timeout: 5_000)
      end
    end
  end
end
