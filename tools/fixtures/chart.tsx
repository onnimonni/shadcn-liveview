import React from "react"
import type { ComponentFixture } from "../fixtures"
import { Area, AreaChart, Bar, BarChart, Line, LineChart } from "recharts"
import { ChartContainer, ChartLegendContent, ChartTooltipContent } from "../../vendor/shadcn/ui/chart"

const config = {
  desktop: { label: "Desktop", color: "#2563eb" },
  mobile: { label: "Mobile", theme: { light: "#16a34a", dark: "#4ade80" } },
}
const configHeex = `[desktop: %{label: "Desktop", color: "#2563eb"}, mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}]`
const data = [
  { month: "January", desktop: 186, mobile: 80 },
  { month: "February", desktop: 305, mobile: 200 },
  { month: "March", desktop: -45, mobile: 120 },
  { month: "April", desktop: 0, mobile: 0 },
]
const dataHeex = `[%{month: "January", desktop: 186, mobile: 80}, %{month: "February", desktop: 305, mobile: 200}, %{month: "March", desktop: -45, mobile: 120}, %{month: "April", desktop: 0, mobile: 0}]`
const payload = [
  { dataKey: "desktop", name: "desktop", value: 1234, color: "#2563eb", payload: { month: "January" } },
  { dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a" },
]
const payloadHeex = `[%{dataKey: "desktop", name: "desktop", value: 1234, color: "#2563eb", payload: %{month: "January"}}, %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}]`

export const fixtures: ComponentFixture[] = [
  {
    name: "chart",
    title: "Chart",
    category: "data-display",
    renderReact: () => <ChartContainer id="viewport" config={{ desktop: config.desktop }} className="min-h-[200px] w-full"><div className="p-4 text-center text-muted-foreground">Chart Viewport</div></ChartContainer>,
    heex: `<.chart_container id="viewport" config={%{desktop: %{label: "Desktop", color: "#2563eb"}}} class="min-h-[200px] w-full"><div class="p-4 text-center text-muted-foreground">Chart Viewport</div></.chart_container>`,
  },
  {
    name: "chart-config-theme", family: "chart", title: "Chart light/dark configuration", category: "data-display",
    renderReact: () => <ChartContainer id="theme-sales" config={config}><div>Theme-aware sales</div></ChartContainer>,
    heex: `<.chart_container id="theme-sales" config={${configHeex}}><div>Theme-aware sales</div></.chart_container>`,
  },
  {
    name: "chart-label-only", family: "chart", title: "Chart without color stylesheet", category: "data-display",
    renderReact: () => <ChartContainer id="label-only" config={{ sales: { label: "Sales" } }} aria-label="Sales report"><div>Sales</div></ChartContainer>,
    heex: `<.chart_container id="label-only" config={%{sales: %{label: "Sales"}}} aria-label="Sales report"><div>Sales</div></.chart_container>`,
  },
  {
    name: "chart-empty-config", family: "chart", title: "Chart empty configuration", category: "data-display",
    renderReact: () => <ChartContainer id="no-config" config={{}}><div>No configured series</div></ChartContainer>,
    heex: `<.chart_container id="no-config" config={%{}}><div>No configured series</div></.chart_container>`,
  },
  {
    name: "chart-bar-series", family: "chart", title: "Responsive signed multi-series bars", category: "data-display",
    renderReact: () => <ChartContainer id="sales-bars" config={config} className="h-[240px] w-full"><div id="sales-bars-canvas"><BarChart data={data}><Bar dataKey="desktop" fill="var(--color-desktop)" /><Bar dataKey="mobile" fill="var(--color-mobile)" /></BarChart></div></ChartContainer>,
    heex: `<.chart_container :let={chart} id="sales-bars" config={${configHeex}} class="h-[240px] w-full"><.chart_canvas id="sales-bars-canvas" context={chart} data={${dataHeex}} series={[:desktop, :mobile]} x_key="month" legend label="Monthly desktop and mobile sales" /></.chart_container>`,
    liveHeex: `<section><button type="button" phx-click="shadcn:chart-data" phx-value-id="sales-bars" value="alternate">Change chart data</button><.chart_container :let={chart} id="sales-bars" config={${configHeex}} class="h-[240px] w-full"><.chart_canvas id="sales-bars-canvas" context={chart} data={if Map.get(@state, "sales-bars") == "alternate", do: [%{month: "May", desktop: 45, mobile: 300}, %{month: "June", desktop: 240, mobile: -30}], else: ${dataHeex}} series={[:desktop, :mobile]} x_key="month" legend label="Monthly desktop and mobile sales" /></.chart_container></section>`,
  },
  {
    name: "chart-line-custom-dimensions", family: "chart", title: "Line chart custom initial dimensions", category: "data-display",
    renderReact: () => <ChartContainer id="trend" config={config} initialDimension={{ width: 480, height: 260 }} className="h-[260px] w-full"><div id="trend-canvas"><LineChart data={data}><Line dataKey="desktop" stroke="var(--color-desktop)" /><Line dataKey="mobile" stroke="var(--color-mobile)" /></LineChart></div></ChartContainer>,
    heex: `<.chart_container :let={chart} id="trend" config={${configHeex}} initial_dimension={%{width: 480, height: 260}} class="h-[260px] w-full"><.chart_canvas id="trend-canvas" context={chart} kind="line" data={${dataHeex}} series={[:desktop, :mobile]} x_key="month" label="Monthly trends" /></.chart_container>`,
  },
  {
    name: "chart-area-gaps", family: "chart", title: "Area chart missing samples", category: "data-display",
    renderReact: () => <ChartContainer id="area" config={{ desktop: config.desktop }} className="h-[200px] w-full"><div id="area-canvas"><AreaChart data={[{ month: "January", desktop: 20 }, { month: "February", desktop: null }, { month: "March", desktop: 40 }]}><Area dataKey="desktop" fill="var(--color-desktop)" stroke="var(--color-desktop)" /></AreaChart></div></ChartContainer>,
    heex: `<.chart_container :let={chart} id="area" config={%{desktop: %{label: "Desktop", color: "#2563eb"}}} class="h-[200px] w-full"><.chart_canvas id="area-canvas" context={chart} kind="area" data={[%{month: "January", desktop: 20}, %{month: "February", desktop: nil}, %{month: "March", desktop: 40}]} series={[:desktop]} x_key="month" /></.chart_container>`,
  },
  {
    name: "chart-empty-data", family: "chart", title: "Chart empty dataset", category: "data-display",
    renderReact: () => <ChartContainer id="empty-data" config={{ desktop: config.desktop }} className="h-[200px] w-full"><div id="empty-data-canvas"><BarChart data={[]}><Bar dataKey="desktop" /></BarChart></div></ChartContainer>,
    heex: `<.chart_container :let={chart} id="empty-data" config={%{desktop: %{label: "Desktop", color: "#2563eb"}}} class="h-[200px] w-full"><.chart_canvas id="empty-data-canvas" context={chart} data={[]} series={[:desktop]} /></.chart_container>`,
  },
  {
    name: "chart-tooltip", family: "chart", title: "Chart active multi-series tooltip", category: "data-display",
    renderReact: () => <ChartContainer id="tooltip" config={config}><section><ChartTooltipContent active payload={payload} label="January" /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="tooltip" config={${configHeex}}><section><.chart_tooltip_content context={chart} active payload={${payloadHeex}} label="January" /></section></.chart_container>`,
  },
  {
    name: "chart-tooltip-line", family: "chart", title: "Chart nested line-indicator tooltip", category: "data-display",
    renderReact: () => <ChartContainer id="tooltip-line" config={config}><section><ChartTooltipContent active payload={[payload[0]]} label="January" indicator="line" /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="tooltip-line" config={${configHeex}}><section><.chart_tooltip_content context={chart} active payload={[%{dataKey: "desktop", name: "desktop", value: 1234, color: "#2563eb"}]} label="January" indicator="line" /></section></.chart_container>`,
  },
  {
    name: "chart-tooltip-hidden", family: "chart", title: "Chart tooltip hidden label and indicator", category: "data-display",
    renderReact: () => <ChartContainer id="tooltip-hidden" config={config}><section><ChartTooltipContent active payload={payload} label="January" hideLabel hideIndicator /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="tooltip-hidden" config={${configHeex}}><section><.chart_tooltip_content context={chart} active payload={${payloadHeex}} label="January" hide_label hide_indicator /></section></.chart_container>`,
  },
  {
    name: "chart-tooltip-inactive", family: "chart", title: "Chart inactive tooltip", category: "data-display",
    renderReact: () => <ChartContainer id="tooltip-inactive" config={config}><section><ChartTooltipContent active={false} payload={payload} /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="tooltip-inactive" config={${configHeex}}><section><.chart_tooltip_content context={chart} payload={${payloadHeex}} /></section></.chart_container>`,
  },
  {
    name: "chart-tooltip-dashed", family: "chart", title: "Chart dashed indicator with zero value", category: "data-display",
    renderReact: () => <ChartContainer id="tooltip-dashed" config={{ desktop: { label: "Desktop" } }}><section><ChartTooltipContent active payload={[{ name: "desktop", value: 0, color: "#123" }]} label="January" indicator="dashed" /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="tooltip-dashed" config={%{desktop: %{label: "Desktop"}}}><section><.chart_tooltip_content context={chart} active payload={[%{name: "desktop", value: 0, color: "#123"}]} label="January" indicator="dashed" /></section></.chart_container>`,
  },
  {
    name: "chart-empty-payload", family: "chart", title: "Chart empty tooltip and legend payloads", category: "data-display",
    renderReact: () => <ChartContainer id="empty-payload" config={{}}><section><ChartTooltipContent active payload={[]} /><ChartLegendContent payload={[]} /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="empty-payload" config={%{}}><section><.chart_tooltip_content context={chart} active payload={[]} /><.chart_legend_content context={chart} payload={[]} /></section></.chart_container>`,
  },
  {
    name: "chart-legend", family: "chart", title: "Chart top legend and filtered payload", category: "data-display",
    renderReact: () => <ChartContainer id="legend" config={config}><section><ChartLegendContent verticalAlign="top" payload={[...payload, { type: "none", dataKey: "ignored", color: "red" }]} /></section></ChartContainer>,
    heex: `<.chart_container :let={chart} id="legend" config={${configHeex}}><section><.chart_legend_content context={chart} vertical_align="top" payload={${payloadHeex.slice(0, -1)}, %{type: "none", dataKey: "ignored", color: "red"}]} /></section></.chart_container>`,
  },
  {
    name: "chart-multiple-instances", family: "chart", title: "Independent chart styles and canvases", category: "data-display",
    renderReact: () => <section><ChartContainer id="first" config={{ sales: { label: "First sales", color: "#9333ea" } }} className="h-[200px] w-full"><div id="first-canvas"><BarChart data={[{ name: "A", sales: 12 }]}><Bar dataKey="sales" /></BarChart></div></ChartContainer><ChartContainer id="second" config={{ sales: { label: "Second sales", theme: { light: "#dc2626", dark: "#f87171" } } }} className="h-[200px] w-full"><div id="second-canvas"><LineChart data={[{ name: "B", sales: 18 }]}><Line dataKey="sales" /></LineChart></div></ChartContainer></section>,
    heex: `<section><.chart_container :let={chart} id="first" config={%{sales: %{label: "First sales", color: "#9333ea"}}} class="h-[200px] w-full"><.chart_canvas id="first-canvas" context={chart} data={[%{name: "A", sales: 12}]} series={[:sales]} /></.chart_container><.chart_container :let={chart} id="second" config={%{sales: %{label: "Second sales", theme: %{light: "#dc2626", dark: "#f87171"}}}} class="h-[200px] w-full"><.chart_canvas id="second-canvas" context={chart} kind="line" data={[%{name: "B", sales: 18}]} series={[:sales]} /></.chart_container></section>`,
  },
]
