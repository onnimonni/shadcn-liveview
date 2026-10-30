# Rules for working with shadcn_liveview

shadcn_liveview is shadcn/ui (Radix Nova) converted to native Phoenix LiveView function
components. There is no React at runtime: interactive families use colocated LiveView hooks,
and the **server owns state** (`open`, `value`, `checked`) through assigns and `handle_event/3`.
These rules override conflicting generic Phoenix guidance (for example "always use
`core_components` `<.input>`/`<.button>`") for code that uses this library.

Set up a Phoenix 1.8 app with `mix igniter.install shadcn_liveview` (installer details and the
manual recipe: `usage-rules/phoenix.md`); afterwards `<.button>`, `<.input>`, `<.table>` and
`<.icon>` are the app's CoreComponents wrappers over this library.

## Find the right component first

- Read `deps/shadcn_liveview/usage-rules/components.md` (generated, always current): one row per
  family with functions, required attrs, allowed enum values, state attrs, events and payloads,
  plus an alias list (toast → `toaster`, modal → `dialog`, link button → `button navigate=`).
- Exact API: `h ShadcnLiveview.Components.Dialog` (or the module source). Attr `values:` are
  enforced at compile time; run `mix compile --warnings-as-errors`.
- Topic rules: `usage-rules/phoenix.md` (install, CoreComponents, daisyUI, dark mode),
  `usage-rules/forms.md`, `usage-rules/overlays.md` (dialog, menus, sidebar, toasts),
  `usage-rules/data-tables.md` (`data_table`: sorting, search, paging, selection, column
  visibility, row menus, URL state).
- Never invent variants, sizes, icon names or attrs from React shadcn memory; check the index.
- Converting a shadcn/ui template (block, example, v0 output, registry URL)? Run
  `node deps/shadcn_liveview/priv/shadcn-to-liveview.mjs <input> --module MyAppWeb.XLive --out ... --report ...`
  and follow `usage-rules/skills/shadcn-template-to-liveview/SKILL.md`.

## State model (applies to every interactive family)

- Give every interactive component a stable, unique `id` that does not change between renders.
- Controlled state lives in your assigns: `open={@open}`, `value={@value}`, `checked={...}`.
  The hook pushes an event (`on_*` attr or its default, e.g. `shadcn:modal-close`,
  `shadcn:popup-change`, `shadcn:tabs-change`); your `handle_event/3` updates the assign.
  Payload keys are strings and always include `"id"`; match on it when several instances exist.
- `default_*` attrs (`default_value`, `default_checked`) are uncontrolled initial values.
- Inside a LiveComponent put `phx-target={@myself}` on the root or a containing element; hooks
  route their events to the nearest `phx-target`.
- Slot context: compound families yield a context with `:let` (`<:content :let={modal}>`); pass
  it to children via `context={modal}` and spread trigger attrs (`{popup.trigger}`) on exactly
  one element. Do not override generated trigger/content IDs separately; pass `trigger_id` on
  the root when focus must return to your own button.

## React shadcn → shadcn_liveview

| React | LiveView |
| --- | --- |
| `className` | `class` (string or HEEx list; caller classes merge after defaults) |
| `onClick` / `onOpenChange` / `onValueChange` | `phx-click`, or the family's `on_*` event + `handle_event/3` |
| `asChild` wrapping `<Link>` | `<.button navigate={~p"/x"}>` / `patch=` / `href=` (renders `<.link>` with button styling) |
| `<Link>` in pagination/breadcrumb/sidebar | `pagination_link`, `breadcrumb_link`, `sidebar_menu_button` with `navigate=`/`patch=` |
| `useState` for open/selected | an assign updated in `handle_event/3` |
| `<Form>` + react-hook-form + zod | `to_form/2` + Ecto changeset + `<.form_field :let={attrs}>` |
| `toast("Saved")` | `push_event(socket, "shadcn:toast", %{toaster: "toaster", message: "Saved"})` |
| `<Toaster />` in the root layout | `<.toaster id="toaster" />` rendered by the LiveView (see overlays.md) |
| lucide-react `<Plus />` | `<.icon name="plus" />` (only names listed in `icon/1` docs) |
| `"use client"` | nothing; hooks are registered once in `app.js` |

## Navigation, icons and styling

- `button` renders `<button>` unless `navigate`, `patch` or `href` is given; then it renders
  `<.link>`. Never hand-write `data-phx-link` attributes.
- `icon/1` supports a curated Lucide set (list in its docs, aliases like `home`, `trash-2`,
  `more-horizontal` accepted) and passes `hero-*` names to phx.new's Heroicons plugin like
  CoreComponents. Unknown names raise at render. Use an inline `<svg>` for one-offs.
- With Tailwind (stock phx.new) import `shadcn.tailwind.css` after `tailwindcss`: components
  compile into your build, your classes override their defaults and token utilities
  (`bg-primary/10`) work in app markup. `shadcn.css` is the prebuilt stylesheet for apps without
  Tailwind; importing it into a Tailwind build makes its utilities beat yours. Never both.
- Theme by overriding CSS variables in `:root` and `[data-theme=dark]`: `--background`,
  `--foreground`, `--card(-foreground)`, `--popover(-foreground)`, `--primary(-foreground)`,
  `--secondary(-foreground)`, `--muted(-foreground)`, `--accent(-foreground)`, `--destructive`,
  `--border`, `--input`, `--ring`, `--chart-1…5`, `--sidebar*`, `--radius`, `--font-sans`,
  `--font-heading` (component titles). There is no `--destructive-foreground`: the
  `destructive` button/badge variant is a tint (`bg-destructive/10 text-destructive`), not solid.
- Default-token contrast is below 4.5:1 for `destructive` buttons/badges, small
  `avatar_fallback` and inactive `tabs_trigger` on custom muted themes; override the tokens (or
  the classes) when axe flags them.
- Any unlayered app selector that can match a component's element beats the components'
  layered utilities: element resets (`a { color: inherit }`, `h1, h2 { font-size: … }` restyles
  `dialog_title`), and descendant selectors (`.hero span { display: block }` breaks `avatar`).
  Target your own classes, scope with `:where(...)`/`:not([data-slot] *)`, or put app CSS in
  `@layer components`.
- Don't put `phx-disable-with` on buttons with icons: LiveView restores it via `textContent`,
  deleting the icon permanently. Use `class="phx-submit-loading:opacity-60"` (or
  `phx-click-loading:`) instead.
- Render both `avatar_image` and `avatar_fallback`: the fallback shows until the image loads and
  again if it fails. `avatar_group` overlaps avatars for photos; two-letter fallback initials get
  clipped in a group, so use single initials or `avatar_group_count` there.
- Chats: wrap the thread in `message_scroller_provider :let={s} auto_scroll` /
  `message_scroller id="..." context={s} class="h-96"` / `message_scroller_viewport context={s}` /
  `message_scroller_content` (follows new messages) rather than a hand-rolled overflow box. A
  composer's blank form re-renders the same `""`, so give its text control (not just the form)
  an id that changes per sent message, or the typed text stays:
  `<.input field={@form[:text]} id={"composer-text-#{@sent_count}"} phx-mounted={@sent_count > 0 && JS.focus()} />`.
  With Credo, enable `ShadcnLiveview.Credo.ComposerFormClears` and
  `ShadcnLiveview.Credo.ChatUsesMessageScroller` (`checks: %{extra: [{..., []}]}`); the
  installer adds them to an existing `.credo.exs`.
- Badge variants are neutral (`default/secondary/destructive/outline/ghost/link`); add status
  colors with your own classes on `badge`.
- `sidebar_inset` renders the page's `<main>`; do not nest another `<main>` inside it.
- `progress` sets the visual value only; add `aria-valuenow`/`aria-label` yourself.
- `use ShadcnLiveview` imports function components only. Module helpers are called by module:
  `ShadcnLiveview.Components.Accordion.accordion_next_value/4`, `Calendar.shift_month/2`, …

## Never

- Never copy React shadcn source or add React, Radix or lucide-react to a Phoenix app.
- Never wrap library components in hand-rolled dialogs, menus or tabs when the family exists.
- Never keep open/selection state only in the browser (JS toggles, `phx-update="ignore"`).
- Never strip LiveView `_unused_*` params when normalizing form attrs (see forms.md).
- Never edit files under `deps/shadcn_liveview`; report library bugs upstream instead.
- Never trust browser-sent values for prices, ownership or authorization; the server validates.

## Verify

- `mix compile --warnings-as-errors` (catches invalid enum values and unknown attrs), `mix test`
  with `Phoenix.LiveViewTest` (`render_click`, `render_change`, `assert_push_event` for toasts).
- SSR tests cannot prove hook behaviour. Drive the running app in a real browser (Playwright) at
  390px and 1280px and check: dialogs/menus open, close on Escape and return focus; native
  `FormData` matches visible checkbox/switch/radio state after rapid clicks followed by typing;
  clearing a pre-filled required field shows an error instead of crashing; focus after
  save/delete lands somewhere sensible; Back/reload restore URL-backed filters; no horizontal
  overflow; axe with overlays open; with the socket disconnected (`liveSocket.disconnect()`),
  unsafe submits are disabled and interacting with hooked components logs no unhandled errors.
- Reachability: at short viewports too (390×600, 1280×600), scroll the document and every scroll
  container to the end and assert the last element of each fixed/sticky panel (sidebar footer,
  dialog footer) has `getBoundingClientRect().bottom <= document.documentElement.clientHeight`.
  Fixed panels cannot scroll the page, so anything past the fold is unreachable.
- Unknown `icon` names compile but raise at render; render every page in a test.
- Run axe after overlay enter animations finish (`document.getAnimations()` settled), and save
  and restore `document.activeElement` around the scan so it doesn't disturb focus assertions.
