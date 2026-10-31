# shadcn-liveview

Native Phoenix LiveView components converted from shadcn/ui's **Radix Nova** registry. Elixir function components use explicit attrs, slots and caller-owned state; interactive behavior uses Phoenix colocated hooks, not a React browser runtime.

Current coverage: **61 component families, 309 SSR fixtures**. React and Phoenix initial HTML are compared with strict generated-ID reference checks. SSR parity is not proof of every browser interaction; connected browser verification is also required for interactive changes.

## Use in a Phoenix app

Consumers use the generated Elixir and shipped assets; they do **not** install this repository's Bun dependencies, React, Tailwind CLI or conversion tools.

### Installer (recommended)

The package ships an [Igniter](https://hexdocs.pm/igniter) installer that turns a stock Phoenix 1.8 `mix phx.new` app into a shadcn_liveview app:

```sh
mix archive.install hex igniter_new   # once, provides mix igniter.install / igniter.new

# existing app
mix igniter.install shadcn_liveview
# local checkout as a path dependency
mix igniter.install shadcn_liveview@path:../shadcn-liveview
# new app
mix igniter.new my_app --with phx.new --with-args="--database sqlite3" --install shadcn_liveview
# dependency already in mix.exs (and igniter available)
mix shadcn_liveview.install
```

It shows a diff and asks before writing (`--yes` skips the prompt). Running it again changes nothing. It:

- imports `shadcn_liveview/priv/static/shadcn.tailwind.css` right after `@import "tailwindcss"` in `assets/css/app.css`, deletes phx.new's `@custom-variant dark` line (the entry covers `.dark` and `[data-theme=dark]`, so the stock theme toggle keeps working) and deletes the daisyUI `@plugin` blocks plus the `:daisyui` dependency (or `assets/vendor/daisyui*.js` in apps from Phoenix 1.8.0/1.8.1); the heroicons plugin stays;
- imports the bundled hooks in `assets/js/app.js` and merges them after the colocated hooks;
- for path dependencies only, adds `Path.join(Mix.Project.build_path(), "lib")` to the esbuild and tailwind `NODE_PATH` (path deps are not copied into `deps/`);
- adds `use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]` next to `import MyAppWeb.CoreComponents` in `html_helpers/0`;
- replaces the daisyUI `CoreComponents` and `Layouts` with shadcn-styled versions that keep Phoenix's API: `<.button variant="primary" navigate=…>` (plus every shadcn variant and size), `<.input field type label options prompt multiple>` (text types, select, textarea, checkbox, hidden), `<.table rows row_id row_click>` with `:col`/`:action`, `<.header>`, `<.list>`, `<.icon name="hero-…">` or Lucide names, `flash`, `show`/`hide`, `translate_error(s)` (Gettext when the app has it), `Layouts.app`, `flash_group` and the `data-theme` `theme_toggle`. `phx.gen.html` and `phx.gen.live` output compiles under `--warnings-as-errors` and renders with shadcn styles;
- maps the stock home page's daisyUI color classes to shadcn tokens;
- adds Credo (`{:credo, "~> 1.7", only: [:dev, :test], runtime: false}`) when the app has none and enables this library's [Credo checks](#credo-checks): in an existing `.credo.exs`, or in a new one that keeps Credo's default checks and lists both under `checks.extra`. After adding Credo it runs `mix deps.compile credo --include-children` and `mix deps.compile shadcn_liveview --force`, because the checks compile only when Credo is loaded and Mix does not rebuild an already compiled shadcn_liveview by itself;
- adds [usage_rules](https://hexdocs.pm/usage_rules) (`{:usage_rules, "~> 1.3", only: [:dev]}`) with the [config below](#for-ai-coding-agents) and runs `mix usage_rules.sync --yes`, which writes this library's rules into `AGENTS.md` (`CLAUDE.md` when only that exists) and its `shadcn-template-to-liveview` skill into `.claude/skills/`. A new config keeps every section already synced into the file (phx.new's `phoenix:*` rules); an existing config keeps its settings and only gets the shadcn_liveview entries (`usage_rules: :all` already covers the rules).

Options: `--no-core-components` keeps your `CoreComponents`/`Layouts` (they still use daisyUI classes), `--keep-daisyui` keeps daisyUI (its `--border` width variable clashes with shadcn's `--border` color token), `--no-credo` and `--no-usage-rules` skip those steps. A file that no longer matches the Phoenix default is left untouched and the installer prints the manual step.

After installing, `<.button>`, `<.input>`, `<.table>` and `<.icon>` are your CoreComponents wrappers over the library; every other component (`dialog`, `card`, `form_field`, …) comes from `use ShadcnLiveview`. Call the library versions of the four wrapped names by module (`<ShadcnLiveview.Components.Button.button>`).

### Manual setup

Add `{:shadcn_liveview, "~> 0.1"}` (or `path: "../shadcn-liveview"` for a local checkout), then run `mix deps.get`. Pick the stylesheet that matches your app:

| Your app | CSS | Hooks |
| --- | --- | --- |
| Tailwind v4 build (stock `mix phx.new`) | `@import "shadcn_liveview/priv/static/shadcn.tailwind.css";` right after `@import "tailwindcss"` in `assets/css/app.css` | `import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"` in `app.js` |
| No Tailwind | serve prebuilt `priv/static/shadcn.css` (Plug.Static, below) | `/shadcn/shadcn-hooks.js` |

The Tailwind entry compiles the components into your own build, so your classes override component defaults and token utilities (`bg-primary/10`) work in app markup. Never import both stylesheets.

```css
/* assets/css/app.css */
@import "tailwindcss" source(none);
@import "shadcn_liveview/priv/static/shadcn.tailwind.css";
/* delete phx.new's @custom-variant dark line; the entry covers .dark and [data-theme=dark] */
```

```js
// assets/js/app.js
import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"
// LiveSocket options: hooks: {...colocatedHooks, ...shadcnHooks}
```

Path dependencies also need `Path.join(Mix.Project.build_path(), "lib")` in the esbuild and tailwind `NODE_PATH`. Import the components with CoreComponents coexistence:

```elixir
# lib/my_app_web.ex, html_helpers/0
import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1, icon: 1]
use ShadcnLiveview  # its icon/1 renders hero-* like CoreComponents plus Lucide names
```

`use ShadcnLiveview` accepts `only:`/`except:` like `import`. The full verified recipe (phx.gen-compatible variant, dark mode via `data-theme`, daisyUI caveats) is in [`usage-rules/phoenix.md`](usage-rules/phoenix.md). Apps without Tailwind can instead serve `priv/static` with `plug Plug.Static, at: "/shadcn", from: :shadcn_liveview, only: ~w(shadcn.css shadcn-hooks.js)`, link `/shadcn/shadcn.css` and import `/shadcn/shadcn-hooks.js` (marked external in esbuild), as `examples/consumer` does. The hook bundle includes all colocated hooks and the carousel's Embla dependency, not React or Phoenix's client.

### For AI coding agents

The package ships agent rules: [`usage-rules.md`](usage-rules.md) plus [`usage-rules/`](usage-rules/) (generated [`components.md`](usage-rules/components.md) index of every family's functions, enum values, state attrs and events; `phoenix.md`, `forms.md`, `overlays.md`, `data-tables.md`) and the package skill [`usage-rules/skills/shadcn-template-to-liveview`](usage-rules/skills/shadcn-template-to-liveview/SKILL.md). The installer syncs them into your app with [usage_rules](https://hexdocs.pm/usage_rules); in a stock phx.new app it writes:

```elixir
# mix.exs project/0, with {:usage_rules, "~> 1.3", only: [:dev]} in deps
usage_rules: [
  file: "AGENTS.md",
  usage_rules: [
    # sync rewrites the whole block: keep phx.new's Phoenix rules explicitly
    "phoenix:elixir", "phoenix:phoenix", "phoenix:ecto", "phoenix:html", "phoenix:liveview",
    # inline the main rules, link the topic rules
    {:shadcn_liveview, sub_rules: []},
    {:shadcn_liveview, sub_rules: :all, main: false, link: :markdown}
  ],
  # copies usage-rules/skills/* to .claude/skills/ (usage_rules' default location)
  skills: [package_skills: [:shadcn_liveview]]
]
```

Rerun `mix usage_rules.sync` after upgrading shadcn_liveview, or point your agent at `deps/shadcn_liveview/usage-rules.md` directly. Agents that read skills elsewhere (e.g. `.agents/skills`) need `skills: [location: ...]`. Component modules carry moduledocs, attr `values:` (invalid literals warn at compile time) and `doc:` text for `h`, ExDoc and Tidewave.

### Phoenix forms

Pass a `Phoenix.HTML.FormField` directly to `input`, `textarea`, `native_select`, `checkbox` or `switch`. IDs, names and current values are inferred; explicit control attributes take precedence. Compose accessible labels, descriptions and errors with `form_field`:

```heex
<.form for={@form} phx-change="validate" phx-submit="save">
  <.form_field field={@form[:email]} label="Email" description="Used for receipts." required :let={attrs}>
    <.input {attrs} type="email" autocomplete="email" />
  </.form_field>
  <.form_field field={@form[:notifications]} label="Email notifications" orientation="horizontal" :let={attrs}>
    <.checkbox {attrs} />
  </.form_field>
  <.button type="submit">Save</.button>
</.form>
```

Assign `@form` with Phoenix `to_form/2`; applications using Ecto changesets also need `phoenix_ecto`. `form_field` shows errors only for used fields, connects help/error IDs through `aria-describedby`, and sets `aria-invalid`. Pass `translate_error={&MyAppWeb.CoreComponents.translate_error/1}` only if your application exposes that function; otherwise provide your own public Gettext translation callback. Without a callback, validation placeholders are interpolated. Field-bound binary controls submit `"false"` when unchecked and `"true"` when checked; explicit `value` can override the checked value. Native multiple selects infer an array-valued form name.

Horizontal checkbox/switch fields place the control first and group label, description and errors beside it. Keep LiveView `_unused_*` parameters when normalizing form input so validation does not expose errors on untouched fields.

For stateful LiveComponents, place `phx-target={@myself}` on the form and explicit action buttons. The native control hooks honor the form owner. Controlled field values reconcile server patches; validation, persistence and reset policy remain owned by your application.

The prebuilt `shadcn.css` (for apps without Tailwind) provides tokens, base styles and the utilities the components use, not arbitrary application utilities; use ordinary CSS for layout, as `examples/consumer` does. Tailwind apps use `shadcn.tailwind.css` instead and get every utility from their own build. Override theme tokens in your own CSS.

### Data tables

`ShadcnLiveview.DataTable` (hand-written, imported by `use ShadcnLiveview`) is a server-side replacement for TanStack Table: `data_table` with `:col` slots, `data_table_search`, `data_table_view_options` and `data_table_pagination`, driven by a `DataTable.State` assign. It covers sorting with `aria-sort`, text and facet filters, page size and paging, per-page select-all with an indeterminate state and selection that survives paging, a column visibility menu, row action menus and focus after deleting a row. `DataTable.from_params/2`/`to_params/1` keep the query in the URL, `apply/2` handles in-memory lists, and `offset/1`/`order_by/1`/`put_total/2` feed Ecto queries. See [`usage-rules/data-tables.md`](usage-rules/data-tables.md); the converter maps TanStack-based templates onto it. A local `data_table/1` function in a module that `use`s the library clashes with the import: rename it or add `except: [data_table: 1]`.

### Credo checks

Apps that use [Credo](https://hex.pm/packages/credo) get two checks from this library (the installer adds Credo, and the checks to `.credo.exs`):

```elixir
# .credo.exs, inside the config map
checks: %{extra: [{ShadcnLiveview.Credo.ComposerFormClears, []}, {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}]}
```

- `ComposerFormClears`: a chat composer (`phx-submit` form with one text control in a template that renders `message`/`bubble`/`message_scroller`) whose control keeps the same DOM id across sends never clears: the blank form re-renders the same `""`. The fix is a per-message control id, e.g. `id={"composer-text-#{@sent_count}"}` plus `phx-mounted={@sent_count > 0 && JS.focus()}`.
- `ChatUsesMessageScroller`: a looped `message`/`bubble` thread in a `message_group`/`bubble_group`, stream container or `overflow-*`/`max-h-*` box without `message_scroller` does not follow new messages.

Both scan `~H` sigils, the colocated `<module>.html.heex` and literal `embed_templates` matches; findings in a `.heex` file are reported on its module, with the template path and line in the message. Run `mix credo explain <file>:<line>` for the full rationale. The checks compile only when Credo is loaded while shadcn_liveview compiles; if you add Credo yourself after shadcn_liveview was built, run `mix deps.compile shadcn_liveview --force` (the installer does this when it adds Credo). Exclude files from a check with Credo's usual params, e.g. `{ShadcnLiveview.Credo.ChatUsesMessageScroller, files: %{excluded: ["lib/my_app_web/live/transcript_live.ex"]}}`.

### Independent consumer example

With the declared toolchain available, run `bash examples/consumer/scripts/dev.sh`. Open **`http://127.0.0.1:4001/shop`** for Northline: an eight-product storefront with search/category/sort/pagination, product options, saved items, a quantity-aware bag, `WELCOME10` discounts, delivery selection, validated checkout, order receipts and browser-owned order history. `/` also opens the storefront. Original SVG product illustrations work offline.

The hero’s “Explore the collection” link smoothly scrolls to the catalog with a 24px top offset. Smooth scrolling is scoped to that in-page link; product navigation starts at the top immediately, and Back restores the previous catalog position without a scroll animation. Scrolling remains instant when the browser’s reduced-motion preference is enabled.

Commerce data uses a single-node DETS store. Carts do not reserve stock; checkout checks and decrements inventory atomically, saves server-authoritative prices, and reuses the signed request token to avoid duplicate orders. Carts, saved items, inventory and orders survive application restarts. The default file is `${XDG_DATA_HOME:-$HOME/.local/share}/shadcn-consumer/shop.dets`; set `SHOP_DATA_PATH` to choose another file. Use a new file path for a fresh catalog rather than deleting active storage.

This is explicitly a **local demo store**: no payment collection, emails or goods dispatch. Customer/address fields are stored locally. Orders belong to the signed browser session, not a user account; clearing cookies loses access to that browser’s history. DETS and a single supervised store process are not a multi-node or production commerce architecture.

Open `/settings` or `/settings/component` for the same validated form in a LiveView or stateful LiveComponent. These existing examples demonstrate confirmation dialogs, toasts, unchecked submission, reset to saved values, server-driven control updates, cross-tab saved-state notifications and genuine Phoenix reconnect form recovery. Saved settings are session-isolated and held in memory: reconnects/reloads retain them, application restarts do not.

Run `mix assets.build && mix test` inside `examples/consumer` for unit, LiveView and real-browser tests. Its test endpoint starts automatically on port 4101; no development server is needed. Browser tests use PhoenixTestPlaywright and capture initial, invalid, confirmation-dialog and saved states with Excessibility. Run `MIX_ENV=test mix excessibility --viewports 390x844,1100x900` there to scan those snapshots. Browser tooling is a test dependency, not a consumer runtime dependency.

The development/release scripts isolate the consumer build directory. When running Mix commands manually from the repository's devenv shell, first `export MIX_BUILD_ROOT="$PWD/_build"` inside `examples/consumer`.

Development/test serve uncompressed assets so old release `.gz` files cannot shadow rebuilt JavaScript or CSS. Production enables gzip serving for release-built assets.

Build a production release with `bash examples/consumer/scripts/release.sh`. Set `SECRET_KEY_BASE` (at least 64 bytes), `PHX_HOST`, `PHX_SERVER=true` and optionally `CONSUMER_PORT` when starting the release. Production expects HTTPS termination by a trusted reverse proxy. Library maintainers regenerate components, then run `mix assets.package` and retain the refreshed `priv/static/shadcn.css`, `shadcn.tailwind.css` and `shadcn-hooks.js` in source control (`test/tailwind-entry.test.ts` fails if the entry and prebuilt CSS diverge). `mix hex.build` includes these public assets while excluding gallery/preview modules and reference/conversion tooling.

### Converting shadcn/ui templates

`priv/shadcn-to-liveview.mjs` converts shadcn/ui blocks, examples and registry items (React/TSX)
into a LiveView module using these components, marking anything it cannot convert with
`TODO(shadcn-to-liveview)` comments and a report:

```sh
node deps/shadcn_liveview/priv/shadcn-to-liveview.mjs https://ui.shadcn.com/r/styles/radix-nova/login-03.json \
  --module MyAppWeb.LoginLive --out lib/my_app_web/live/login_live.ex --report login_live.md
```

Agents: follow `usage-rules/skills/shadcn-template-to-liveview/SKILL.md`. `mix assets.package`
rebuilds the converter bundle with the other packaged assets.

## Development

Recommended: install [devenv](https://devenv.sh/getting-started/) and enter the declared toolchain:

```sh
devenv shell
setup-project
setup-browser
test-components
test-browser-components
```

`devenv.nix` declares Bun, the Node compatibility runtime used by `tsx`, Elixir/Mix, matching Erlang/OTP, Rebar3, Bash, Git and GitHub CLI. Phoenix/Credo come from `mix.lock`; esbuild, Tailwind and the React reference dependencies come from the JavaScript package lockfile. Setup installs Hex and project dependencies explicitly; shell entry does not install them. BEAM build artifacts are isolated under devenv's state directory, avoiding conflicts with host toolchain versions.

Available shell commands:

| Command | Action |
| --- | --- |
| `setup-project` | Install Hex, fetch root/consumer Mix dependencies and install Bun dependencies. |
| `generate-components` | Regenerate and format native components. |
| `check-components` | Run `mix quality`. |
| `test-components` | Run the generation/quality/test/SSR-parity pipeline. |
| `setup-browser` | Install pinned Playwright Chromium; Linux browser tests can use Nix Chromium. |
| `test-browser-components` | Run Elixir component/consumer browser tests and retained React/visual comparisons. |
| `test-accessibility` | Capture connected HTML, then scan both projects with Excessibility; findings exit nonzero. |
| `update-shadcn` | Refresh the live upstream registry snapshot; follow the review procedure below. |
| `preview-components` | Build assets and launch the connected preview on port 4000. |

Without devenv, provide Elixir 1.18+ (within 1.x), matching Erlang/OTP, Rebar3, Bun, the `tsx` compatibility runtime and Bash, then run `mix local.hex --force`, `mix deps.get`, `bun install`, `bunx playwright install chromium` and `bun run test`. Fetch the example's dependencies with `(cd examples/consumer && mix deps.get)` before combined browser/accessibility commands. Git/GitHub CLI are needed for repository maintenance.

`bun run test` regenerates components, formats generated Elixir, checks formatting and warning-free HEEx/Elixir compilation, runs strict Credo, validates the references in the shipped agent rules (`mix usage_rules.validate`), runs converter/comparator and ExUnit tests, builds assets, and compares all SSR fixtures. Any failed case or family exits nonzero.

`bun run test:browser` runs PhoenixTestPlaywright ExUnit suites and the consumer browser flows, then starts/stops a preview on port 4000 for retained React/visual comparisons; stop other previews first. Elixir test endpoints use ports 4100 and 4101. Tests exercise native form values, patches/reset, controlled transitions, LiveComponent targeting, keyboard/pointer actions, popup focus/dismissal, scrolling and responsive layouts. Outside devenv, install Chromium with `bunx playwright install chromium`; Linux also needs the browser's system libraries. `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH` selects an installed Chromium for the browser driver.

Generated-component browser tests live in `test/browser/*_test.exs` and use [PhoenixTestPlaywright](https://phoenix-test-playwright.hexdocs.pm/readme.html). Shared helpers observe browser state and send real Playwright input actions; they do not replace component hooks with mocks. TypeScript remains for React-reference and screenshot-audit tooling.

### Accessibility tests

[Excessibility](https://github.com/lessthanseventy/excessibility) captures connected browser DOM, including selected/open/error states, rather than only initial server HTML. Snapshots live in ignored `test/excessibility/html_snapshots/` directories in each project. Static assets resolve from the application or library package; both projects reuse the root Playwright and axe-core installation.

Run `bun run test:a11y --viewports 390x844,1100x900` after setup. This runs browser tests, then scans all existing snapshots in both projects with axe-core and LiveView-aware rules. It checks overwritten snapshots too; it does not rely on the package's combined test command, which scans only newly named files. Findings and scanner failures exit nonzero; no rules are disabled or baselines automatically approved. Snapshots cannot prove keyboard behavior or every interaction state: functional browser tests remain required.

Current snapshots report missing accessible control names/labels, contrast failures and LiveView-aware click/live-region findings. The accessibility command intentionally remains nonzero until those findings are resolved.

### Static scan and dependency patch

Run `bunx aislop scan`. `.aislop/config.yml` classifies only intentional CLI output, canonical public links and the scanner's template-interpolation unused-import false positives; syntax-aware linting and security audits remain enabled. Generator parsing/rendering and hook sources are split by domain rather than hidden behind file-size exceptions.

`braces@3.0.3` has no published fix for [CVE-2026-93687](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm). The approved local Bun patch in `patches/braces@3.0.3.patch` bounds brace/parenthesis parsing and all recursive AST walkers to 128 nesting levels. Root and `login-preview` manifests apply the same patch; use `bun install --frozen-lockfile` in each project. Legacy npm lockfiles do not apply Bun patches. Regression tests cover ordinary expansion, the nesting boundary, deeply nested input and direct AST entrypoints.

Version-based audits still report the upstream advisory despite the local mitigation; it is deliberately not suppressed. Replace the patch with an audited upstream release when available.

```sh
mix quality                 # formatter, compiler, strict Credo, agent-rule references
bun run generate            # local vendored source → formatted Elixir/HEEx
bun run test:parity          # asset build + React/Phoenix SSR comparison
SHADCN_PREVIEW=1 mix run --no-halt
```

Interactive galleries: [React](http://127.0.0.1:4000/preview/react-ssr.html) and [LiveView](http://127.0.0.1:4000/preview/liveview.html). Both contain all 309 examples in the same order. Each example runs in an independent iframe, preserving viewport-bound dialogs/drawers, focus traps, form state and IDs without affecting neighboring cards. React mounts the actual vendored components; LiveView uses native components, server events and colocated hooks, not a React runtime.

The 309 gallery compositions are **locally authored regression fixtures**, not official shadcn examples. Original React components are imported from the fetched registry snapshot. Official examples and blocks are separately stored in `vendor/shadcn/examples/` and `vendor/shadcn/blocks/`; their untouched originals live under `vendor/shadcn/upstream/`. The galleries label this distinction and link each family to its upstream registry response. Downloading a block does not convert that entire application template into Phoenix.

Galleries reserve each component family's minimum viewport height and load nearby frames ahead of scrolling. LiveView frames report their content height after connection, avoiding transient SSR-to-hook resizing; later interaction-driven resizing remains enabled.

The multi-sidebar demo uses bounded desktop providers and stacks them at mobile widths; its mobile navigation still opens as a viewport-bound modal overlay. Responsive chart demos give their outer layout a shrinkable, full-width wrapper. Shipping radios have visible associated labels and separate submit/status rows, rather than bare controls.

The original `/preview/react-ssr.html` URL now opens the interactive React gallery. Zero-JavaScript comparison galleries remain at `/preview/react-static.html` and `/preview/phoenix-ssr.html`. Asset builds generate the React/static/interactive preview pages. These fixtures include intentional disabled, controlled, empty and force-mounted cases; matching SSR does not prove client-side behavior or measured chart/scroller layout.

Standalone connected preview: <http://127.0.0.1:4000/live-preview/accordion>. Choose another fixture using its selector. `?embed=1` renders only that fixture; React's equivalent is `/preview/react-fixture.html?fixture=accordion`. Browser builds use a separate alias map so the SSR-only portal shim never replaces real React portals.

### Screenshot anomaly audit

With the preview running, `devenv shell -- bun run audit:visual` captures every fixture in React and LiveView at 390px and 1100px widths. It writes a ranked likely-broken review queue, paired screenshots, PNG differences, geometry/hit-test evidence, and structured JSON under `parity/visual-audit/`.

```sh
# Focus on reported examples; serve the report through the preview endpoint.
devenv shell -- bun run audit:visual \
  --fixtures sidebar-multiple,chart-bar-series,radio-group-required-vertical \
  --out priv/static/preview/visual-audit
```

Open `/preview/visual-audit/index.html` for that output. `--url` selects the preview endpoint, `--widths` changes the viewport list, and `--strict` exits nonzero on warning/error findings, not informational differences. The default run reports findings (including capture failures) for review without treating every intentional demo state as a failure; always check its coverage counts.

Capture readiness follows React commits (including portal-only fixtures) or the connected LiveView socket, then loaded fonts/images and settled chart geometry. Render crashes and readiness timeouts are recorded as failed captures, never successful blank screenshots. The React gallery control adapter preserves single-element `asChild` triggers while binding interactive state. Gallery family height floors live on a document-level CSS variable so LiveView connection and subsequent patches cannot discard them.

Independent checks cover overflow/clipping, intersecting menu/listbox panels (including nested panels), overlapping controls, nine-point control occlusion, horizontal navigation cross-axis misalignment, and crowded controls. Hit tests include expanded pseudo-element click areas that extend beyond border boxes. Shared edges/subpixel overlap are ignored; minor panel contact and spacing remain low-confidence evidence. Label/backing-input relationships, compound control groups, and intentional modal coverage are excluded where applicable.

Occlusion samples are evidence, not exhaustive coverage: one or two intercepted points are retained as informational findings; three to five are warnings; six or more are errors. Unsampled thin hit areas can still be missed, so a clean scan does not prove every clickable pixel works.

Clipping and occlusion sampling share containing-block-aware overflow rules: viewport-positioned popups can escape intermediate overflow ancestors, while transformed/contained positioned ancestors and ordinary scroll/hidden content retain applicable clipping. Paired geometry separately flags stage differences above 1px and uniquely named control differences above 4px; ambiguous repeated names are not matched. This catches sparse demos shifting despite a low changed-pixel ratio.

`report.json` retains every result and adds `rankedSuspects`: scores prioritize capture failures, blocked controls and layout geometry over pixel differences and label heuristics. Repeated DOM descendants/ancestor-clipping cascades cannot inflate priority. Each suspect links the paired images, raw evidence and live fixtures; shared React/LiveView signals retain priority. Scores are review priorities, not probabilities or accessibility certification.

This is a heuristic audit, not aesthetic certification. Both implementations can reproduce a bad locally authored fixture; matching React is not proof of correct presentation. Initial states can also differ, so changed pixels alone are not proven regressions. The audit captures initial demo states, including explicitly open-state fixtures; it does not crawl clicks or keyboard transitions. Review interactions separately and inspect coverage/capture failures before concluding a component is sound.

### Component integration

Use `use ShadcnLiveview` in a Phoenix component/LiveView module to import the components. `ShadcnLiveview.Form` documents Phoenix field bindings and accessible composition; compound component modules document controlled state and event payloads. Consumers can use the shipped CSS/hooks described above. Custom asset builds can instead register the compiled colocated `hooks` manifest with their `LiveSocket`, as shown in `assets/js/preview.js`; bundle vanilla `embla-carousel` 8.6.0 when doing so.

Checkbox, switch and slider `default_checked`/`default_value` initialize uncontrolled state once. Local state survives unrelated patches and later default changes; explicit `checked`/`value` assigns remain authoritative. Reset matches each vendored primitive: switch/slider restore mounted defaults; a checkbox resets its visual state through its nearest wrapping form, while an externally associated checkbox resets submitted values without changing its visual check. Hook-generated events honor the nearest `phx-target`, including `@myself` in stateful LiveComponents; absent targets route to the owning LiveView. Wrapperless popup/modal/combobox roots forward their supplied target to native hook owners.

Hook-generated events never raise unhandled rejections when LiveView is disconnected or the server fails the push. Server-controlled widgets keep their last rendered state: accordion, tabs, collapsible, toggle, popups, modals, menubar, navigation menu and calendar months simply do not change, while controlled checkbox, switch, slider, radio/toggle group, command and combobox selections roll back their optimistic repaint. Client-owned state (uncontrolled controls, typed OTP/questionnaire input, carousel, resizable and sidebar) stays local; only the server notification is lost. Interactions retry normally after reconnecting.

Textarea `value` renders escaped content, not an HTML `value` attribute; explicit values (including `""`) override the slot. Missing values use slot content and otherwise remain truly empty. ScrollArea enables native scrolling on connection without requiring a root ID.

Questionnaires preserve repeated native field names for multiple choices. Their hooks send array-valued `phx-change`/`phx-submit` payloads directly, avoiding Phoenix's duplicate-name URL decoding; clearing the last choice sends an empty array. Scalar-only forms retain normal Phoenix transport.

Native notifications: mount `<.toaster id="notifications" />`, then `push_event(socket, "shadcn:toast", %{toaster: "notifications", message: "Saved", description: "Changes saved.", duration: 4000})`. Messages are escaped text; zero duration persists until dismissed. Explicit dismissal, automatic expiry and Alt+T focus use the colocated notification hook, not React.

## Updating from upstream shadcn/ui

### Sources of truth

| Path | Role |
| --- | --- |
| `tools/vendor.mjs` | Fetches official Radix Nova UI, examples, blocks and support entries. |
| `tools/verify-upstream.mjs` | Verifies original payloads/source and alias-only project copies; `--remote` compares every item with the live official URL again. |
| `vendor/shadcn/registry.lock.json` | Official URLs, fetch time, exact payload/source hashes and project-copy hashes. |
| `vendor/shadcn/registry/` | Exact fetched registry index and item JSON responses. |
| `vendor/shadcn/upstream/` | Untouched file contents extracted from those responses, preserving original registry paths. |
| `vendor/shadcn/ui/`, `hooks/`, `lib/`, `examples/`, `blocks/`, `components/` | Project copies; only `@/components/ui/` import aliases are rewritten. |
| `package.json`, `bun.lock` | React reference renderer, registry dependencies and conversion/build tooling. `package-lock.json` records the original npm snapshot used for the Bun migration. |
| `devenv.nix`, `devenv.yaml`, `devenv.lock` | Declared developer tools and locked Nix inputs; toolchain updates are separate from registry updates. |
| `tools/generate.tsx` | Generic source extraction, module imports and gallery generation. |
| `tools/converters/` | Native conversion rules for compound and interactive families. |
| `tools/icons.ts` | Canonical SVG extraction from Lucide. |
| `tools/fixtures.tsx`, `tools/fixtures/` | Locally authored paired React/HEEx regression cases and interactive state owners, not official templates. |
| `lib/shadcn_liveview/components/`, `gallery.ex`, `lib/shadcn_liveview.ex` | Generated outputs; do not fix these by hand. |
| `lib/shadcn_liveview/helpers.ex`, `preview.ex` | Handwritten runtime helpers and connected verification app. |

The source is the [live Radix Nova registry](https://ui.shadcn.com/r/styles/radix-nova/registry.json), not a pinned Git revision. The snapshot contains 62 UI registry entries: 61 contain implementations; the advertised `form` response has no files. It also includes 65 official examples, 30 blocks and 3 support entries. Exact upstream payloads and source are preserved alongside alias-adjusted copies. The local Lucide `IconPlaceholder` adapter under `vendor/shadcn/app/` is project integration code, not a claimed upstream file. The lock does not freeze the registry server or install dependencies. Normal generation/tests do not fetch upstream.

### Update procedure

1. **Start from a clean checkout and create an update branch.** Keep the previous Git commit as the reproducible baseline; a later registry fetch may return different content.

   ```sh
   git switch -c update/shadcn-ui
   bun run vendor
   bun run verify:upstream --remote
   git diff -- vendor/shadcn
   ```

   `bun run vendor` refetches all UI/example/block/component/lib/hook entries, writes exact payloads and untouched originals, updates project copies and records provenance in `registry.lock.json`. `bun run verify:upstream` verifies local integrity; `--remote` compares each saved item response against its official URL. Review markup, variants, exports, hooks and dependencies. Failed fetching can leave a partial update; restore/retry before generating or committing.

2. **Reconcile dependencies explicitly.** Compare dependency names in the new registry lock with `package.json`. The vendor command does not modify dependency versions. Add/update the required packages with Bun, preserving deliberate version pins, and commit the resulting package manifest/lockfile changes. Do not upgrade unrelated packages as part of the conversion.

   ```sh
   bun add --exact PACKAGE@VERSION
   ```

   This is a command template: replace `PACKAGE@VERSION` with a reviewed dependency/version. Commit `package.json` and `bun.lock` together. Setup uses `bun install --frozen-lockfile`, so stale manifest/lockfile pairs fail rather than silently resolving new versions.

3. **Regenerate and fix conversion rules, not generated modules.**

   ```sh
   bun run generate
   ```

   Styling/primitive changes may be extracted automatically. Structural, behavior or API changes can require edits in the relevant `tools/converters/*.ts`, generic generator or handwritten runtime helpers. Regeneration overwrites generated Elixir.

   For each changed family, update the paired React and HEEx fixtures using the same inputs and supported public APIs. Add meaningful boundary cases: disabled states, controlled/default values, native forms, multiple instances, orientation and relevant transitions. Add/update `liveHeex` when server reconciliation needs verification.

   New upstream families require fixtures: generation rejects missing family coverage and duplicate fixture names. Implement their native conversion before treating the update as complete. The vendor and generator commands do **not** prune removed files; review removals against the old registry lock and explicitly remove obsolete vendored/generated files and migrate affected imports, fixtures and callers.

4. **Run all quality and parity gates.**

   ```sh
   bun run test
   ```

   Fix compiler warnings, Credo findings, behavioral failures and every SSR discrepancy. Do not weaken the comparator, substitute saved HTML for native components, or edit generated HTML snapshots to make an update pass. Keep generated component modules and SSR preview outputs together with the source/rule changes.

5. **Verify the real browser behavior.** Start the connected preview after the successful asset build. Exercise changed families with actual keyboard/pointer actions and server patches. Check disabled/required boundaries, form data, independent instances, focus/scroll restoration, responsive layout and listener/DOM cleanup. For layout changes, compare the React and Phoenix static galleries with JavaScript disabled; compare animations at the same phase.

6. **Commit one reviewed update.** Include vendored source and registry lock, dependency changes, conversion rules/helpers, fixtures/tests, regenerated Elixir and generated SSR artifacts. Rebuild and retain the shipped `priv/static/shadcn.css`, `shadcn.tailwind.css` and `shadcn-hooks.js`; exclude preview bundles. Update affected component docs in the generator/converter and this README if the workflow or coverage changes. Do not commit `node_modules`, `deps`, `_build` or other built asset bundles.

An upstream refresh is **not** a promise of automatic compatibility: React/Radix/Base UI behavioral changes need an explicit native LiveView implementation and verification. The gates identify drift; they do not replace that work.

## Upstream attribution

shadcn/ui upstream: <https://github.com/shadcn-ui/ui>. Its MIT copyright/permission notice is retained in [`vendor/shadcn/LICENSE`](vendor/shadcn/LICENSE), including for upstream-derived component styles and markup.
