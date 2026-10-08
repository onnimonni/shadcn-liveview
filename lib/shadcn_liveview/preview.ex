defmodule ShadcnLiveview.Preview do
  @moduledoc """
  Local, connected component gallery. Start with `SHADCN_PREVIEW=1 mix run --no-halt`.
  SSR-only comparison galleries remain in `priv/static/preview`; this gallery exercises
  real LiveView events, patches and colocated hook lifecycles at `/live-preview/:fixture`.
  """
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>LiveView component preview</title>
        <link rel="stylesheet" href="/assets/css/app.css" />
        <script type="module" src="/assets/js/preview.js">
        </script>
      </head>
      <body class="min-h-screen bg-background text-foreground antialiased">
        {@inner_content}
      </body>
    </html>
    """
  end
end

defmodule ShadcnLiveview.Preview.Live do
  @moduledoc false
  use Phoenix.LiveView, layout: false
  alias ShadcnLiveview.Components.Calendar
  alias ShadcnLiveview.Gallery

  @value_events ~w(shadcn:accordion-change shadcn:tabs-change shadcn:selection-change
    shadcn:menubar-change shadcn:menu-check-change shadcn:menu-radio-change shadcn:menubar-sub-change
    shadcn:carousel-change shadcn:resizable-change
    shadcn:chart-data shadcn:questionnaire-change shadcn:command-change
    shadcn:combobox-change shadcn:otp-change shadcn:otp-complete shadcn:message-count control_change)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %{}, form_data: %{}, names: Gallery.names())}
  end

  @impl true
  def handle_params(%{"fixture" => fixture}, _uri, socket) do
    if fixture in Gallery.names() do
      {:noreply, assign(socket, fixture: fixture, state: %{}, form_data: %{})}
    else
      {:noreply, push_navigate(socket, to: "/live-preview/#{hd(Gallery.names())}")}
    end
  end

  @impl true
  def handle_event("preview:fixture", %{"fixture" => fixture}, socket) do
    {:noreply, push_navigate(socket, to: "/live-preview/#{fixture}")}
  end

  def handle_event("preview:form", params, socket),
    do: {:noreply, assign(socket, :form_data, params)}

  def handle_event(event, %{"id" => id, "value" => value}, socket) when event in @value_events do
    {:noreply, put_state(socket, id, value)}
  end

  def handle_event("shadcn:modal-open", %{"id" => id}, socket),
    do: {:noreply, put_state(socket, id, true)}

  def handle_event("shadcn:modal-close", %{"id" => id}, socket),
    do: {:noreply, put_state(socket, id, false)}

  def handle_event("shadcn:sidebar-change", %{"id" => id, "open" => open}, socket),
    do: {:noreply, put_state(socket, id, open)}

  def handle_event("control_open", %{"id" => id, "open" => open}, socket),
    do: {:noreply, put_state(socket, id, open)}

  def handle_event("shadcn:combobox-open", %{"id" => id, "open" => open}, socket),
    do: {:noreply, put_state(socket, "#{id}-open", open)}

  def handle_event("shadcn:popup-change", %{"id" => id, "action" => action} = params, socket) do
    socket = put_state(socket, "#{id}-open", action == "open")

    socket = popup_selection(socket, id, action, params)

    {:noreply, socket}
  end

  def handle_event("calendar-month", %{"id" => id} = params, socket) do
    state = Calendar.change_month(calendar_state(socket, id), params)
    {:noreply, put_state(socket, id, state)}
  end

  def handle_event("calendar-select", %{"id" => id} = params, socket) do
    state = Calendar.select_date(calendar_state(socket, id), params)
    {:noreply, put_state(socket, id, state)}
  end

  def handle_event(event, %{"id" => id} = params, socket)
      when event in ~w(shadcn:questionnaire-answer shadcn:questionnaire-submit) do
    answers = Map.drop(params, ~w(_target id item on-item-change))
    socket = put_state(socket, "#{id}-answers", answers)

    socket =
      if event == "shadcn:questionnaire-submit",
        do: put_state(socket, "#{id}-submitted", true),
        else: socket

    {:noreply, assign(socket, :form_data, Map.put(socket.assigns.form_data, event, params))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-7xl space-y-6 p-8">
      <h1 class="text-2xl font-semibold">Connected LiveView component preview</h1>
      <form id="fixture-navigation" phx-change="preview:fixture">
        <label for="fixture">Fixture</label>
        <select id="fixture" name="fixture" class="ml-4 rounded border bg-background p-2">
          <option :for={name <- @names} value={name} selected={name == @fixture}>{name}</option>
        </select>
      </form>
      <section id="component-preview" class="rounded-lg border p-8">
        <Gallery.live_fixture fixture={@fixture} state={@state} />
      </section>
      <output id="preview-state" class="block whitespace-pre-wrap text-xs">{Jason.encode!(@state)}</output>
      <output id="preview-form-data" class="block whitespace-pre-wrap text-xs">{Jason.encode!(
        @form_data
      )}</output>
    </main>
    """
  end

  defp put_state(socket, id, value),
    do: assign(socket, :state, Map.put(socket.assigns.state, id, value))

  defp popup_selection(socket, id, "select", %{
         "value" => value,
         "checked" => checked,
         "role" => "menuitemcheckbox"
       }),
       do: put_state(socket, "#{id}-#{value}-checked", checked)

  defp popup_selection(socket, id, "select", %{"value" => value}),
    do: put_state(socket, "#{id}-value", value)

  defp popup_selection(socket, _id, _action, _params), do: socket

  defp calendar_state(socket, id) do
    Map.get(socket.assigns.state, id, %{
      month: ~D[2024-02-01],
      mode: "single",
      selected: ~D[2024-02-29]
    })
  end
end

defmodule ShadcnLiveview.Preview.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, html: {ShadcnLiveview.Preview, :root}
  end

  scope "/" do
    pipe_through :browser
    live "/live-preview/:fixture", ShadcnLiveview.Preview.Live
  end
end

defmodule ShadcnLiveview.Preview.ErrorHTML do
  @moduledoc false
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule ShadcnLiveview.Preview.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :shadcn_liveview

  @session_options [
    store: :cookie,
    key: "_shadcn_preview",
    signing_salt: "preview-gallery",
    same_site: "Lax"
  ]
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  plug Plug.Static, at: "/", from: :shadcn_liveview, gzip: false, only: ~w(assets preview)
  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.Session, @session_options
  plug ShadcnLiveview.Preview.Router
end
