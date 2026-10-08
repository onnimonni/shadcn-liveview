defmodule ShadcnLiveview do
  @moduledoc """
  Shadcn component library for Phoenix LiveView.
  Provides all 61 Radix-Nova shadcn components as Phoenix function components.

  Run `mix assets.build` before SSR previews. The CSS pipeline bundles imports and
  embeds fonts, then compiles Tailwind utilities; asset failures stop parity runs.

  Run `bun run generate` to convert the pinned upstream source and format emitted
  Elixir/HEEx. Complex components use dedicated structural converters with explicit
  attrs, slots, stable caller IDs and controlled state; no hidden rendering context.
  Register `hooks` exported from the compiled colocated manifest in your LiveSocket.

  `mix quality` enforces formatter checks, warning-free HEEx/Elixir compilation,
  strict Credo and the LiveView assign/change-tracking rules on generated modules.
  `bun run test` regenerates components, runs that quality gate, behavior tests and
  SSR comparison. Every fixture and every covered family must pass; failures exit
  nonzero. IDs may differ only for generated identities; reference graphs remain strict.

  Start `SHADCN_PREVIEW=1 mix run --no-halt` and visit
  `http://127.0.0.1:4000/live-preview/accordion` to exercise real LiveView patches
  and colocated hooks. `bun run test:parity` compares all 309 initial-render cases.
  SSR parity alone does not prove every prop or browser interaction.
  """

  defmacro __using__(_opts) do
    quote do
      import ShadcnLiveview.Components.Icon
      import ShadcnLiveview.Components.Accordion
      import ShadcnLiveview.Components.AlertDialog
      import ShadcnLiveview.Components.Alert
      import ShadcnLiveview.Components.AspectRatio
      import ShadcnLiveview.Components.Attachment
      import ShadcnLiveview.Components.Avatar
      import ShadcnLiveview.Components.Badge
      import ShadcnLiveview.Components.Breadcrumb
      import ShadcnLiveview.Components.Bubble
      import ShadcnLiveview.Components.ButtonGroup
      import ShadcnLiveview.Components.Button
      import ShadcnLiveview.Components.Calendar
      import ShadcnLiveview.Components.Card
      import ShadcnLiveview.Components.Carousel
      import ShadcnLiveview.Components.Chart
      import ShadcnLiveview.Components.Checkbox
      import ShadcnLiveview.Components.Collapsible
      import ShadcnLiveview.Components.Combobox
      import ShadcnLiveview.Components.Command
      import ShadcnLiveview.Components.ContextMenu
      import ShadcnLiveview.Components.Dialog
      import ShadcnLiveview.Components.Direction
      import ShadcnLiveview.Components.Drawer
      import ShadcnLiveview.Components.DropdownMenu
      import ShadcnLiveview.Components.Empty
      import ShadcnLiveview.Components.Field
      import ShadcnLiveview.Components.HoverCard
      import ShadcnLiveview.Components.InputGroup
      import ShadcnLiveview.Components.InputOtp
      import ShadcnLiveview.Components.Input
      import ShadcnLiveview.Components.Item
      import ShadcnLiveview.Components.Kbd
      import ShadcnLiveview.Components.Label
      import ShadcnLiveview.Components.Marker
      import ShadcnLiveview.Components.Menubar
      import ShadcnLiveview.Components.MessageScroller
      import ShadcnLiveview.Components.Message
      import ShadcnLiveview.Components.NativeSelect
      import ShadcnLiveview.Components.NavigationMenu
      import ShadcnLiveview.Components.Pagination
      import ShadcnLiveview.Components.Popover
      import ShadcnLiveview.Components.Progress
      import ShadcnLiveview.Components.Questionnaire
      import ShadcnLiveview.Components.RadioGroup
      import ShadcnLiveview.Components.Resizable
      import ShadcnLiveview.Components.ScrollArea
      import ShadcnLiveview.Components.Select
      import ShadcnLiveview.Components.Separator
      import ShadcnLiveview.Components.Sheet
      import ShadcnLiveview.Components.Sidebar
      import ShadcnLiveview.Components.Skeleton
      import ShadcnLiveview.Components.Slider
      import ShadcnLiveview.Components.Sonner
      import ShadcnLiveview.Components.Spinner
      import ShadcnLiveview.Components.Switch
      import ShadcnLiveview.Components.Table
      import ShadcnLiveview.Components.Tabs
      import ShadcnLiveview.Components.Textarea
      import ShadcnLiveview.Components.ToggleGroup
      import ShadcnLiveview.Components.Toggle
      import ShadcnLiveview.Components.Tooltip
    end
  end
end
