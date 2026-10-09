import fs from "node:fs/promises"
import path from "node:path"
import { fixtures } from "./fixtures"
import { cn } from "cn"
import { generateIcons } from "./icons"
import { generateComponent as linked } from "./converters/linked"
import { generateComponent as modals } from "./converters/modals"
import { generateComponent as popups } from "./converters/popups"
import { generateComponent as command } from "./converters/command"
import { generateComponent as calendar } from "./converters/calendar"
import { generateComponent as layout } from "./converters/layout"
import { generateComponent as chart } from "./converters/chart"
import { generateComponent as conversation } from "./converters/conversation"
import { generateComponent as selections } from "./converters/selections"
import { generateComponent as controls } from "./converters/controls"
import { generateComponent as toggle } from "./converters/toggle"
import { parseComponent } from "./generator/parser"
import { generateBasicFunction } from "./generator/basic"
import { generateNativeFunction } from "./generator/native"
import { generateNavigationFunction } from "./generator/navigation"
import { generateStructuralFunction } from "./generator/structural"

export interface ComponentSpec {
  name: string
  moduleName: string
  functions: ComponentFunctionSpec[]
}

export interface ComponentFunctionSpec {
  name: string
  tag: string
  slotName: string
  baseClasses: string
  variants?: Record<string, Record<string, string>>
  defaultVariants?: Record<string, string>
  attrs?: { name: string; type: string; default?: string }[]
  extraInnerMarkup?: string
  hasDataVariant?: boolean
  hasDataSize?: boolean
  staticAttrs?: string[]
}

export function generateElixirModule(spec: ComponentSpec): string {
  for (const convert of [linked, modals, popups, command, calendar, layout, chart, conversation, selections, controls, toggle]) {
    const component = convert(spec)
    if (component !== undefined) return component
  }
  const funcsCode = spec.functions
    .map(fn => generateStructuralFunction(fn) ?? generateNativeFunction(fn) ?? generateNavigationFunction(fn) ?? generateBasicFunction(fn))
    .join("\n\n")
  const helpersImport = funcsCode.includes("classes(") ? "  import ShadcnLiveview.Helpers\n" : ""

  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc false
  use Phoenix.Component
${helpersImport}
${funcsCode}
end
`
}

export function parseComponentAST(fileName: string, code: string): ComponentSpec {
  return parseComponent(fileName, code)
}

export async function generateAllComponents(): Promise<void> {
  const outDir = path.resolve("lib/shadcn_liveview/components")
  await fs.mkdir(outDir, { recursive: true })
  await generateIcons()

  const files = (await fs.readdir("vendor/shadcn/ui")).filter((f) => f.endsWith(".tsx")).sort()
  console.log(`Found ${files.length} vendored UI component files.`)
  const coveredFamilies = new Set(fixtures.map(fixture => fixture.family ?? fixture.name))
  const missingFamilies = files.map(file => file.replace(/\.tsx$/, "")).filter(family => !coveredFamilies.has(family))
  if (missingFamilies.length) throw new Error(`Missing family fixtures: ${missingFamilies.join(", ")}`)
  const names = fixtures.map(fixture => fixture.name)
  if (new Set(names).size !== names.length) throw new Error("Duplicate fixture names")

  const moduleNames: string[] = []
  const inheritedClasses = new Map<string, string>()
  for (const [control, target] of [["input", "input_group_input"], ["textarea", "input_group_textarea"], ["label", "field_label"]]) {
    const source = await fs.readFile(path.join("vendor/shadcn/ui", control + ".tsx"), "utf8")
    const controlSpec = parseComponentAST(control, source)
    inheritedClasses.set(target, controlSpec.functions.find((fn) => fn.name === control)!.baseClasses)
  }

  for (const f of files) {
    const compName = f.replace(/\.tsx$/, "")
    const code = await fs.readFile(path.join("vendor/shadcn/ui", f), "utf8")
    const spec = parseComponentAST(compName, code)
    // Compound controls compose upstream primitive styles before local overrides.
    for (const fn of spec.functions) {
      const inherited = inheritedClasses.get(fn.name)
      if (inherited) fn.baseClasses = cn(inherited, fn.baseClasses)
    }
    const elixirCode = generateElixirModule(spec)
    const outPath = path.join(outDir, `${compName.replace(/-/g, "_")}.ex`)
    await fs.writeFile(outPath, elixirCode, "utf8")
    moduleNames.push(spec.moduleName)
  }

  // Generate umbrella module lib/shadcn_liveview.ex
  const importsList = moduleNames.map((m) => `      import ShadcnLiveview.Components.${m}`).join("\n")

  const umbrellaCode = `defmodule ShadcnLiveview do
  @moduledoc """
  Shadcn component library for Phoenix LiveView.
  Provides all 61 Radix-Nova shadcn components as Phoenix function components.

  Run \`mix assets.build\` before SSR previews. The CSS pipeline bundles imports and
  embeds fonts, then compiles Tailwind utilities; asset failures stop parity runs.

  Run \`bun run generate\` to convert the pinned upstream source and format emitted
  Elixir/HEEx. Complex components use dedicated structural converters with explicit
  attrs, slots, stable caller IDs and controlled state; no hidden rendering context.
  Register \`hooks\` exported from the compiled colocated manifest in your LiveSocket.

  \`mix quality\` enforces formatter checks, warning-free HEEx/Elixir compilation,
  strict Credo and the LiveView assign/change-tracking rules on generated modules.
  \`bun run test\` regenerates components, runs that quality gate, behavior tests and
  SSR comparison. Every fixture and every covered family must pass; failures exit
  nonzero. IDs may differ only for generated identities; reference graphs remain strict.

  Start \`SHADCN_PREVIEW=1 mix run --no-halt\` and visit
  \`http://127.0.0.1:4000/live-preview/accordion\` to exercise real LiveView patches
  and colocated hooks. \`bun run test:parity\` compares all 309 initial-render cases.
  SSR parity alone does not prove every prop or browser interaction.
  """

  defmacro __using__(_opts) do
    quote do
      import ShadcnLiveview.Components.Icon
${importsList}
    end
  end
end
`
  await fs.writeFile("lib/shadcn_liveview.ex", umbrellaCode, "utf8")
  console.log(`Generated lib/shadcn_liveview.ex with ${moduleNames.length} component modules.`)

  // Generate lib/shadcn_liveview/gallery.ex
  const galleryCases = fixtures
    .map((f) => {
      const indented = f.heex
        .split("\n")
        .map((l) => "    " + l)
        .join("\n")
      return `  def render_fixture("${f.name}") do\n    assigns = %{}\n    ~H"""\n${indented}\n    """\n  end`
    })
    .join("\n\n")
  const liveGalleryCases = fixtures.map((f) => {
    const indented = (f.liveHeex ?? f.heex).split("\n").map((line) => "    " + line).join("\n")
    return `  def live_fixture(%{fixture: "${f.name}"} = assigns) do\n    ~H"""\n${indented}\n    """\n  end`
  }).join("\n\n")

  const namesList = fixtures.map((f) => `"${f.name}"`).join(", ")
  const entriesList = fixtures.map((f) => `%{name: ${JSON.stringify(f.name)}, title: ${JSON.stringify(f.title)}, category: ${JSON.stringify(f.category)}, family: ${JSON.stringify(f.family || f.name)}}`).join(",\n    ")
  const galleryCode = `defmodule ShadcnLiveview.Gallery do
  @moduledoc false
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  def names, do: [${namesList}]

  def entries, do: [
    ${entriesList}
  ]

  def render_html(name) do
    case render_fixture(name) do
      nil -> nil
      rendered -> Safe.to_iodata(rendered) |> IO.iodata_to_binary()
    end
  end

  def dump_all do
    names()
    |> Enum.map(fn name -> {name, render_html(name)} end)
    |> Map.new()
    |> Jason.encode!()
  end

${galleryCases}

  def render_fixture(_), do: nil

  attr :fixture, :string, required: true
  attr :state, :map, required: true
  attr :form_data, :map, required: true
  @doc "Renders a connected fixture using the caller's tracked state and submitted form data."

${liveGalleryCases}

  def live_fixture(%{fixture: fixture}),
    do: raise(ArgumentError, "Unknown component fixture: #{inspect(fixture)}")
end
`
  await fs.writeFile("lib/shadcn_liveview/gallery.ex", galleryCode, "utf8")
  console.log(`Generated lib/shadcn_liveview/gallery.ex with ${fixtures.length} fixture renderers.`)
}

async function runCli(): Promise<void> {
  const isDirect = process.argv[1]?.endsWith("generate.tsx") || process.argv[1]?.endsWith("generate.ts")
  if (isDirect) {
    await generateAllComponents()
  }
}

runCli().catch((err) => {
  console.error("Component generation failed:", err)
  process.exit(1)
})
