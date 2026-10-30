# Dialogs, menus, sidebar and toasts

All overlays are server-controlled: render them with an `open` assign, handle the hook's
event, and update the assign. Closed content is not rendered.

## Dialog / alert dialog / sheet / drawer

```heex
<.button id="new-task" phx-click="new-task">New task</.button>

<.dialog id="task-dialog" open={@dialog_open} trigger_id="new-task">
  <:content :let={modal}>
    <.dialog_content context={modal} aria-labelledby={modal.title_id} aria-describedby={modal.description_id}>
      <.dialog_header>
        <.dialog_title context={modal}>New task</.dialog_title>
        <.dialog_description context={modal}>Add a task to the board.</.dialog_description>
      </.dialog_header>
      <.form for={@task_form} id="task-form" phx-change="validate-task" phx-submit="save-task">
        …
        <.dialog_footer>
          <.dialog_close context={modal}>Cancel</.dialog_close>
          <.button type="submit">Create</.button>
        </.dialog_footer>
      </.form>
    </.dialog_content>
  </:content>
</.dialog>
```

```elixir
def handle_event("new-task", _, socket), do: {:noreply, assign(socket, dialog_open: true)}
# Escape, overlay click and dialog_close push this with %{"id" => "task-dialog"}:
def handle_event("shadcn:modal-close", %{"id" => "task-dialog"}, socket),
  do: {:noreply, assign(socket, dialog_open: false)}
```

- `trigger_id` tells the hook where to return focus; point it at the button that opened the
  dialog. `dialog_trigger` (spread with context) also works but has no default styling.
- Several dialogs on one page share `shadcn:modal-close`; match on `"id"` and keep a catch-all
  clause.
- `alert_dialog` has the same contract (`alert_dialog_action`/`alert_dialog_cancel`), `sheet`
  adds `side=`, `drawer` adds `direction=`. Widen content with a class on `dialog_content`
  (your app CSS must provide that utility). `dialog_close`, `sheet_close` and `drawer_close` are
  unstyled by default (like Radix); pass `variant`/`size` to style them as buttons.
- Modal triggers, overlays and close controls follow the nearest `phx-target`, so a
  LiveComponent wrapper with `phx-target={@myself}` is enough; an explicit `target` still wins.
- Select, menu, popover, tooltip and hover-card content is shown in the browser's top layer, so
  it escapes `relative z-0` table rows and transformed parents (drawers) without workarounds.
- Menus opened by pointer focus the menu itself; keyboard opens focus the first item (ArrowUp:
  the last). Drawers focus themselves on open (Vaul's default), not their first input.
- Sheet, drawer, dialog and alert-dialog content scroll inside themselves when taller than the
  viewport (library base-layer guard), so footers stay reachable while body scroll is locked.
  Don't add `overflow-hidden`/`max-h-*` to the content unless you scroll an inner region.
- Focus restoration on close (Escape, cancel, successful save) is owned by the hook via
  `trigger_id`; do not push competing focus commands then. A dropdown menu's trigger id is
  `"<menu id>-trigger"`, so a dialog opened from row menu `task-menu-7` uses
  `trigger_id="task-menu-7-trigger"`. Only when the trigger disappears (deleted row) move focus
  explicitly (`JS.focus(to: "#tasks-heading")` or a small hook); otherwise it falls to `<body>`.
- For a delete confirmation, `alert_dialog_action on_click={JS.push("delete", value: %{id: id})}`
  pushes your event and then closes the dialog.

## Dropdown / context menu / popover / select / tooltip

```heex
<.dropdown_menu id={"task-menu-#{task.id}"} open={@open_menu == task.id} align="end">
  <:trigger :let={popup}>
    <.button variant="ghost" size="icon-sm" aria-label={"Actions for #{task.title}"} {popup.trigger}>
      <.icon name="more-horizontal" />
    </.button>
  </:trigger>
  <:content :let={popup}>
    <.dropdown_menu_content context={popup}>
      <.dropdown_menu_item value="edit">Edit</.dropdown_menu_item>
      <.dropdown_menu_separator />
      <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
    </.dropdown_menu_content>
  </:content>
</.dropdown_menu>
```

```elixir
def handle_event("shadcn:popup-change", %{"id" => "task-menu-" <> id} = params, socket) do
  case params do
    %{"action" => "open"} -> {:noreply, assign(socket, open_menu: id)}
    %{"action" => "close"} -> {:noreply, assign(socket, open_menu: nil)}
    %{"action" => "select", "value" => action} -> socket |> assign(open_menu: nil) |> run(action, id)
  end
end
```

- Payload: `%{"id", "action", "value"}` (items also send `"role"` and, for checkbox/radio items,
  `"checked"`); a selection sends `select` then `close`. Item `value`
  falls back to its text. Compare `open_menu` with the same type you put in the id.
- The same `shadcn:popup-change` event drives popover, hover_card, select, context_menu and
  tooltip; match on `"id"`.
- Menus inside streamed rows: see data-tables.md (do not reset the whole stream to open a menu).

## Sidebar

`sidebar_provider` yields `:let={sidebar}`; pass it to `sidebar`, `sidebar_trigger` and
`sidebar_rail`. `open`/`mobile_open` are your assigns; the hook pushes
`shadcn:sidebar-change` with `%{"id" => provider_id, "open" => bool}` (desktop) and
`provider_id <> "-mobile"` (drawer). Handle it once for every LiveView with `on_mount` in a
`live_session`. The hook also writes a `sidebar_state` cookie (`"true"`/`"false"`); reading it
keeps a collapsed sidebar collapsed across live navigation and reloads (verified):

```elixir
# router.ex
live_session :app, on_mount: [{MyAppWeb.Sidebar, :sidebar}], session: {MyAppWeb.Sidebar, :session, []} do
  # live routes…
end

defmodule MyAppWeb.Sidebar do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  # First (disconnected) render: cookie from the HTTP request, so no expand flash on reload.
  def session(conn), do: %{"sidebar_state" => conn.cookies["sidebar_state"]}

  def on_mount(:sidebar, _params, session, socket) do
    # Connected joins (including live navigation) re-read the cookie via connect params.
    state = if connected?(socket), do: get_connect_params(socket)["sidebar_state"], else: session["sidebar_state"]
    socket = socket |> assign(:sidebar_open, state != "false") |> assign(:sidebar_mobile_open, false)

    # Ids are the sidebar_provider id (here "app-sidebar"), not the inner sidebar's id.
    # Assert the assign changes in a test; a catch-all clause silently drops mismatched ids.
    {:cont, attach_hook(socket, :sidebar, :handle_event, fn
      "shadcn:sidebar-change", %{"id" => "app-sidebar-mobile", "open" => open}, socket ->
        {:halt, assign(socket, :sidebar_mobile_open, open)}
      "shadcn:sidebar-change", %{"id" => "app-sidebar", "open" => open}, socket ->
        {:halt, assign(socket, :sidebar_open, open)}
      _event, _params, socket -> {:cont, socket}
    end)}
  end
end
```

```js
// app.js: a params *function* is re-evaluated on every LiveView join, including live navigation
params: () => ({_csrf_token: csrfToken, sidebar_state: document.cookie.match(/(?:^|; )sidebar_state=(\w+)/)?.[1]})
```

Use `sidebar_menu_button navigate={~p"/app"} is_active={…}` for links. `sidebar_inset` is the
page `<main>`. A collapsed offcanvas sidebar's links are off-screen, so browser tests must
expand it before clicking them.

## Toasts

Mount the toaster inside LiveView-rendered markup (a shared app-shell function component), not
the root layout, so `push_event/3` reaches it:

```heex
<.toaster id="toaster" />
```

```elixir
push_event(socket, "shadcn:toast", %{toaster: "toaster", message: "Task saved", description: "Visible to your team.", duration: 4000})
```

`duration: 0` persists until dismissed. Messages are escaped text. Test with
`assert_push_event(view, "shadcn:toast", %{message: "Task saved"})`. The toaster renders a
`<section>` in normal flow; inside a flex/grid container with `gap` it adds an empty gap, so mount
it outside the flex flow or give it `class="contents"`.
