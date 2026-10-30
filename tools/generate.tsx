import fs from "node:fs/promises"
import path from "node:path"
import { fixtures } from "./fixtures"
import type { ComponentFixture } from "./fixtures"
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
import { basicModuleDoc, documentAttrs, type ModuleDocSource } from "./generator/module-docs"
import { upstreamDocsUrl } from "./generator/component-index"

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
  attrs?: { name: string; type: string; default?: string; values?: string[]; doc?: string }[]
  /** Replaces the default `{render_slot(@inner_block)}` body of a basic element. */
  innerMarkup?: string
  hasDataVariant?: boolean
  hasDataSize?: boolean
  staticAttrs?: string[]
}

export function generateElixirModule(spec: ComponentSpec, docs: ModuleDocSource): string {
  return documentAttrs(generateModuleSource(spec, docs))
}

function generateModuleSource(spec: ComponentSpec, docs: ModuleDocSource): string {
  for (const convert of [linked, modals, popups, command, calendar, layout, chart, conversation, selections, controls, toggle]) {
    const component = convert(spec)
    if (component !== undefined) return component
  }
  const funcsCode = spec.functions
    .map(fn => generateStructuralFunction(fn) ?? generateNativeFunction(fn) ?? generateNavigationFunction(fn) ?? generateBasicFunction(fn))
    .join("\n\n")
  const helpersImport = funcsCode.includes("classes(") ? "  import ShadcnLiveview.Helpers\n" : ""

  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
${basicModuleDoc(spec, funcsCode, docs)}
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

  const families: { moduleName: string; category: ComponentFixture["category"] }[] = []
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
    const familyFixtures = fixtures.filter(fixture => (fixture.family ?? fixture.name) === compName)
    const primaryFixture = familyFixtures.find(fixture => fixture.name === compName) ?? familyFixtures[0]
    const registry = JSON.parse(await fs.readFile(path.join("vendor/shadcn/registry", compName + ".json"), "utf8"))
    const elixirCode = generateElixirModule(spec, {
      docsUrl: upstreamDocsUrl(registry, compName),
      example: primaryFixture.heex,
    })
    const outPath = path.join(outDir, `${compName.replace(/-/g, "_")}.ex`)
    await fs.writeFile(outPath, elixirCode, "utf8")
    families.push({ moduleName: spec.moduleName, category: primaryFixture.category })
  }

  // Generate umbrella module lib/shadcn_liveview.ex
  const fence = "```"
  const categoryTitles: Record<ComponentFixture["category"], string> = {
    "actions": "Actions", "data-display": "Data display", "feedback": "Feedback", "forms": "Forms",
    "layout": "Layout", "navigation": "Navigation", "overlay": "Overlays",
  }
  const familyList = Object.entries(categoryTitles).map(([category, title]) => {
    const modules = families.filter(family => family.category === category)
      .map(family => `\`ShadcnLiveview.Components.${family.moduleName}\``)
    return `  * ${title}: ${modules.join(", ")}`
  }).join("\n")
  const familyModules = ["Icon", ...families.map(family => family.moduleName)]
    .map(moduleName => `    ShadcnLiveview.Components.${moduleName}`).join(",\n")

  const umbrellaCode = `defmodule ShadcnLiveview do
  @moduledoc """
  Phoenix LiveView function components converted from shadcn/ui's
  [Radix Nova registry](https://ui.shadcn.com/r/styles/radix-nova/registry.json).
  Interactive behavior uses Phoenix colocated hooks; no React runtime is involved.

  ## Installation

  In a Phoenix 1.8 app, run the bundled Igniter installer (the \`igniter_new\`
  archive provides \`mix igniter.install\`):

  ${fence}sh
  mix igniter.install shadcn_liveview
  ${fence}

  It wires the assets and hooks below, removes daisyUI, adds
  \`use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]\` to
  \`html_helpers\` and replaces the daisyUI \`CoreComponents\`/\`Layouts\` with
  shadcn-styled versions that keep Phoenix's API, so \`phx.gen.*\` output keeps
  working. See \`Mix.Tasks.ShadcnLiveview.Install\` for flags.

  For a manual setup add \`:shadcn_liveview\` to your \`mix.exs\` dependencies and run
  \`mix deps.get\`.
  The package ships \`priv/static/shadcn.tailwind.css\` (Tailwind v4 source entry),
  prebuilt \`priv/static/shadcn.css\` and \`priv/static/shadcn-hooks.js\`; consumers need
  neither React nor this project's conversion tooling. Agent rules ship in
  \`usage-rules.md\` and \`usage-rules/\` (component index: \`usage-rules/components.md\`).

  ## Assets

  In a stock \`phx.new\` app, import the Tailwind entry right after Tailwind in
  \`assets/css/app.css\` (and delete phx.new's \`@custom-variant dark\` line):

  ${fence}css
  @import "tailwindcss" source(none);
  @import "shadcn_liveview/priv/static/shadcn.tailwind.css";
  ${fence}

  and merge the hook registry into your LiveSocket in \`assets/js/app.js\`:

  ${fence}js
  import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"

  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: {...colocatedHooks, ...shadcnHooks},
    // ...your existing options
  })
  ${fence}

  Path dependencies also need \`Path.join(Mix.Project.build_path(), "lib")\` in the
  esbuild and tailwind \`NODE_PATH\`. Apps without Tailwind instead serve the prebuilt
  files with
  \`plug Plug.Static, at: "/shadcn", from: :shadcn_liveview, only: ~w(shadcn.css shadcn-hooks.js)\`.
  Never import both stylesheets.
  Dark tokens and \`dark:\` utilities apply inside either a \`.dark\` element or
  Phoenix 1.8's \`[data-theme=dark]\`, so the stock theme toggle needs no bridge.

  ## Importing components

  \`use ShadcnLiveview\` imports the function components (arity 1) of every family
  plus \`ShadcnLiveview.Form.form_field/1\` and the \`ShadcnLiveview.DataTable\`
  components (\`data_table/1\`, \`data_table_search/1\`, \`data_table_view_options/1\`,
  \`data_table_pagination/1\`); module helpers such as \`Calendar.shift_month/2\` or
  \`DataTable.apply/2\` are not imported. Pass \`only:\` or \`except:\` with
  \`name: arity\` pairs to filter across all families, as with \`Kernel.import/2\`.

  Phoenix 1.8 \`CoreComponents\` also defines \`button/1\`, \`input/1\`, \`icon/1\` and
  \`table/1\`. The installer keeps those four in CoreComponents (rewritten over this
  library, with the API \`mix phx.gen.live\`/\`phx.gen.html\` templates call) and
  imports everything else:

  ${fence}elixir
  import MyAppWeb.CoreComponents
  use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]
  ${fence}

  Without generated templates you can instead exclude the four from CoreComponents
  (\`import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1, icon: 1]\`
  plus \`use ShadcnLiveview\`); this library's \`icon/1\` renders \`hero-*\` names like
  CoreComponents and every other name from its Lucide set.

  ## State, forms and events

  Interactive components are server-controlled: give each a stable \`id\`, keep
  state such as \`open\` or \`value\` in assigns, and handle the \`on_*\` event that
  each module documents. Bind controls to Phoenix \`to_form/2\` fields with
  \`field={@form[:name]}\`; \`form_field/1\` adds labels, descriptions and used-field
  errors around \`input\`, \`textarea\`, \`native_select\`, \`checkbox\` and \`switch\`.
  See \`ShadcnLiveview.Form\`. Sortable, filterable, paginated tables with row
  selection keep their state in a \`ShadcnLiveview.DataTable.State\` assign; see
  \`ShadcnLiveview.DataTable\`.

  ## Component families

${familyList}
  * Icons: \`ShadcnLiveview.Components.Icon\` (Lucide)
  """

  @families [
${familyModules}
  ]
  @extra_imports [
    {ShadcnLiveview.Form, [form_field: 1]},
    {ShadcnLiveview.DataTable,
     [data_table: 1, data_table_search: 1, data_table_view_options: 1, data_table_pagination: 1]}
  ]

  @doc """
  Imports every family's function components, \`ShadcnLiveview.Form.form_field/1\` and
  the \`ShadcnLiveview.DataTable\` components.

  \`only:\` or \`except:\` (mutually exclusive) take \`name: arity\` keyword lists
  applied across all families, as with \`Kernel.import/2\`. Names that are not
  imported components raise \`ArgumentError\`.

      use ShadcnLiveview, except: [icon: 1]
      use ShadcnLiveview, only: [button: 1, card: 1, card_content: 1]
  """
  defmacro __using__(opts) do
    imports =
      for {module, import_opts} <- import_plan(opts) do
        quote do: import(unquote(module), unquote(import_opts))
      end

    {:__block__, [], imports}
  end

  defp import_plan(opts) do
    case import_filter!(opts) do
      nil -> Enum.map(@families, &{&1, only: components(&1)}) ++ Enum.map(@extra_imports, fn {module, names} -> {module, only: names} end)
      {kind, names} -> filtered_import_plan(kind, names)
    end
  end

  defp import_filter!(opts) do
    if not Keyword.keyword?(opts) do
      raise ArgumentError, "use ShadcnLiveview expects a keyword list, got: #{inspect(opts)}"
    end

    case Keyword.split(opts, [:only, :except]) do
      {[], []} ->
        nil

      {[{kind, names}], []} ->
        {kind, validate_names!(kind, names)}

      {_filters, []} ->
        raise ArgumentError, "use ShadcnLiveview accepts either :only or :except, not both"

      {_filters, unknown} ->
        raise ArgumentError,
              "use ShadcnLiveview got unknown options #{inspect(Keyword.keys(unknown))}; " <>
                "expected :only or :except"
    end
  end

  defp validate_names!(kind, names) do
    if Keyword.keyword?(names) and Enum.all?(names, fn {_name, arity} -> is_integer(arity) and arity >= 0 end) do
      names
    else
      raise ArgumentError,
            "use ShadcnLiveview expects #{kind}: to be a keyword list of name: arity, got: #{inspect(names)}"
    end
  end

  defp filtered_import_plan(kind, names) do
    exports = Enum.map(@families, &{&1, components(&1)}) ++ @extra_imports
    available = Enum.flat_map(exports, &elem(&1, 1))

    case Enum.reject(names, &(&1 in available)) do
      [] ->
        :ok

      unknown ->
        raise ArgumentError,
              "use ShadcnLiveview, #{kind}: no component family exports #{inspect(unknown)}"
    end

    Enum.flat_map(exports, fn {module, functions} ->
      kept = if kind == :only, do: Enum.filter(functions, &(&1 in names)), else: functions -- names
      if kept == [], do: [], else: [{module, only: kept}]
    end)
  end

  # Function components only (arity 1); module helpers such as
  # Calendar.shift_month/2 stay callable by their qualified name.
  defp components(module) do
    for {name, 1} <- Code.ensure_compiled!(module).__info__(:functions),
        not String.starts_with?(Atom.to_string(name), "_"),
        do: {name, 1}
  end
end
`
  await fs.writeFile("lib/shadcn_liveview.ex", umbrellaCode, "utf8")
  console.log(`Generated lib/shadcn_liveview.ex with ${families.length} component modules.`)

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
