defmodule ShadcnLiveview.Preview.ChartLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  @sales [
    %{month: "January", desktop: 186, mobile: 80},
    %{month: "February", desktop: 305, mobile: 200},
    %{month: "March", desktop: 237, mobile: 120},
    %{month: "April", desktop: 73, mobile: 190}
  ]

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, sales: @sales, tick: 0)}

  @impl true
  def handle_event("tick", _params, socket), do: {:noreply, update(socket, :tick, &(&1 + 1))}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8" style="width:640px">
      <h1>Chart feature harness</h1>
      <button id="chart-patch" type="button" phx-click="tick">Patch</button>
      <output id="chart-tick">{@tick}</output>
      <.chart_container
        id="custom-fill"
        config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
        class="h-[200px] w-full"
      >
        <:custom :let={chart}>
          <div id="custom-fill-child" class="h-full w-full" data-context={chart.id}></div>
        </:custom>
      </.chart_container>
      <.chart_container
        :let={chart}
        id="custom-mixed"
        config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
        class="h-[200px] w-full"
      >
        <.chart_tooltip_content context={chart} payload={[]} />
        <:custom>
          <svg id="custom-mixed-svg" width="100%" height="100%" role="img" aria-label="Custom chart">
            <rect width="100%" height="100%" fill="var(--color-desktop)" />
          </svg>
        </:custom>
      </.chart_container>
      <.chart_container
        :let={chart}
        id="stacked-bars"
        config={
          %{
            desktop: %{label: "Desktop", color: "#2563eb"},
            mobile: %{label: "Mobile", color: "#16a34a"}
          }
        }
        class="h-[240px] w-full"
      >
        <.chart_canvas
          id="stacked-bars-canvas"
          context={chart}
          data={@sales}
          series={[:desktop, :mobile]}
          x_key="month"
          stack="sales"
          grid="both"
          fill="gradient"
          label="Stacked sales"
        />
      </.chart_container>
      <.chart_container
        :let={chart}
        id="curves"
        config={
          %{
            desktop: %{label: "Desktop", color: "#2563eb"},
            mobile: %{label: "Mobile", color: "#16a34a"}
          }
        }
        class="h-[240px] w-full"
      >
        <.chart_canvas
          id="monotone-line"
          context={chart}
          kind="line"
          curve="monotone"
          data={@sales}
          series={[:desktop]}
          x_key="month"
          tick_format={&String.slice(&1, 0, 3)}
          label="Monotone line"
        />
      </.chart_container>
      <.chart_container
        :let={chart}
        id="steps"
        config={%{mobile: %{label: "Mobile", color: "#16a34a"}}}
        class="h-[240px] w-full"
      >
        <.chart_canvas
          id="step-area"
          context={chart}
          kind="area"
          curve="step"
          data={@sales}
          series={[:mobile]}
          x_key="month"
          label="Step area"
        />
      </.chart_container>
    </main>
    """
  end
end
