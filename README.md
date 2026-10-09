# shadcn-liveview

Native Phoenix LiveView components converted from shadcn/ui's **Radix Nova** registry. Elixir function components use explicit attrs, slots and caller-owned state; interactive behavior uses Phoenix colocated hooks, not a React browser runtime.

Current coverage: **61 component families, 309 SSR fixtures**. React and Phoenix initial HTML are compared with strict generated-ID reference checks. SSR parity is not proof of every browser interaction; connected browser verification is also required for interactive changes.

## Development

Recommended: install [devenv](https://devenv.sh/getting-started/) and enter the declared toolchain:

```sh
devenv shell
setup-project
test-components
setup-browser
test-browser-components
```

`devenv.nix` declares Bun, the Node compatibility runtime used by `tsx`, Elixir/Mix, matching Erlang/OTP, Rebar3, Bash, Git and GitHub CLI. Phoenix/Credo come from `mix.lock`; esbuild, Tailwind and the React reference dependencies come from the JavaScript package lockfile. Setup installs Hex and project dependencies explicitly; shell entry does not install them. BEAM build artifacts are isolated under devenv's state directory, avoiding conflicts with host toolchain versions.

Available shell commands:

| Command | Action |
| --- | --- |
| `setup-project` | Install Hex, fetch Mix dependencies and install Bun dependencies. |
| `generate-components` | Regenerate and format native components. |
| `check-components` | Run `mix quality`. |
| `test-components` | Run the generation/quality/test/SSR-parity pipeline. |
| `setup-browser` | Install pinned Playwright Chromium on macOS; Linux uses Nix Chromium. |
| `test-browser-components` | Launch an isolated preview and run connected browser regressions. |
| `update-shadcn` | Refresh the live upstream registry snapshot; follow the review procedure below. |
| `preview-components` | Build assets and launch the connected preview on port 4000. |

Without devenv, provide Elixir 1.18+ (within 1.x), matching Erlang/OTP, Rebar3, Bun, the `tsx` compatibility runtime and Bash, then run `mix local.hex --force`, `mix deps.get`, `bun install` and `bun run test`. Git/GitHub CLI are needed for repository maintenance.

`bun run test` regenerates components, formats generated Elixir, checks formatting and warning-free HEEx/Elixir compilation, runs strict Credo, runs converter/comparator and ExUnit tests, builds assets, and compares all SSR fixtures. Any failed case or family exits nonzero.

`bun run test:browser` starts/stops its own preview on port 4000; stop other previews first. It verifies native form values, uncontrolled patches/reset, controlled updates/transitions, LiveComponent event routing, textarea escaping/patches, disabled combobox input, nested disclosure ownership and ScrollArea wheel/touch/keyboard scrolling. Paired regressions cover controlled tabs, independent instances, frame-contained dialogs, post-patch slider focus, disabled slider submission, external-form resets, separator sizing/reset, centered looping carousels and repeated questionnaire answers. Outside devenv, first run `bunx playwright install chromium` (Linux also needs Playwright's browser system libraries), or set `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH` to an installed Chromium.

`test/browser/components-{basic,controls,layout,popups}.spec.ts` gives every one of the 61 implemented component families a named Phoenix Playwright check. Interactive checks use connected LiveView events, keyboard/pointer actions, form values and acknowledged state; static checks compare actual browser layout with React. These checks supplement, not replace, the regression suites.

### Static scan and dependency patch

Run `bunx aislop scan`. `.aislop/config.yml` classifies only intentional CLI output, canonical public links and the scanner's template-interpolation unused-import false positives; syntax-aware linting and security audits remain enabled. Generator parsing/rendering and hook sources are split by domain rather than hidden behind file-size exceptions.

`braces@3.0.3` has no published fix for [CVE-2026-93687](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm). The approved local Bun patch in `patches/braces@3.0.3.patch` bounds brace/parenthesis parsing and all recursive AST walkers to 128 nesting levels. Root and `login-preview` manifests apply the same patch; use `bun install --frozen-lockfile` in each project. Legacy npm lockfiles do not apply Bun patches. Regression tests cover ordinary expansion, the nesting boundary, deeply nested input and direct AST entrypoints.

Version-based audits still report the upstream advisory despite the local mitigation; it is deliberately not suppressed. Replace the patch with an audited upstream release when available.

```sh
mix quality                 # formatter, compiler and strict Credo
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

With the preview running, `devenv shell -- bun run audit:visual` captures every fixture in React and LiveView at 390px and 1100px widths. It writes a paired-image HTML report, PNG differences, measurements, and structured JSON under `parity/visual-audit/`.

```sh
# Focus on reported examples; serve the report through the preview endpoint.
devenv shell -- bun run audit:visual \
  --fixtures sidebar-multiple,chart-bar-series,radio-group-required-vertical \
  --out priv/static/preview/visual-audit
```

Open `/preview/visual-audit/index.html` for that output. `--url` selects the preview endpoint, `--widths` changes the viewport list, and `--strict` exits nonzero on warning/error findings, not informational differences. The default run reports findings (including capture failures) for review without treating every intentional demo state as a failure; always check its coverage counts.

Capture readiness follows React commits (including portal-only fixtures) or the connected LiveView socket, then loaded fonts/images and settled chart geometry. Render crashes and readiness timeouts are recorded as failed captures, never successful blank screenshots. The React gallery control adapter preserves single-element `asChild` triggers while binding interactive state.

This is a heuristic audit, not aesthetic certification: it compares actual rendered images and flags overflow/clipping and suspicious controls. Identical bad React and Phoenix layouts can pass pixel comparison, so geometry and label checks run independently. Initial captures do not prove every interaction state; behavioral Playwright tests remain required.

### Component integration

Use `use ShadcnLiveview` in a Phoenix component/LiveView module to import the components. Component module docs describe controlled state and event payloads. Consumers must register the compiled colocated `hooks` with their `LiveSocket`; `assets/js/preview.js` demonstrates this integration. Build/include the project's CSS as well as the hook bundle. The carousel uses vanilla `embla-carousel` 8.6.0, not React; include that dependency when bundling the hooks in another asset project.

Checkbox, switch and slider `default_checked`/`default_value` initialize uncontrolled state once. Local state survives unrelated patches and later default changes; explicit `checked`/`value` assigns remain authoritative. Reset matches each vendored primitive: switch/slider restore mounted defaults; a checkbox resets its visual state through its nearest wrapping form, while an externally associated checkbox resets submitted values without changing its visual check. Hook-generated events honor the nearest `phx-target`, including `@myself` in stateful LiveComponents; absent targets route to the owning LiveView. Wrapperless popup/modal/combobox roots forward their supplied target to native hook owners.

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

6. **Commit one reviewed update.** Include vendored source and registry lock, dependency changes, conversion rules/helpers, fixtures/tests, regenerated Elixir and generated SSR artifacts. Update affected component docs in the generator/converter and this README if the workflow or coverage changes. Do not commit `node_modules`, `deps`, `_build` or built asset bundles.

An upstream refresh is **not** a promise of automatic compatibility: React/Radix/Base UI behavioral changes need an explicit native LiveView implementation and verification. The gates identify drift; they do not replace that work.

## Upstream attribution

shadcn/ui upstream: <https://github.com/shadcn-ui/ui>. Its MIT copyright/permission notice is retained in [`vendor/shadcn/LICENSE`](vendor/shadcn/LICENSE), including for upstream-derived component styles and markup.
