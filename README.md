# shadcn-liveview

Native Phoenix LiveView components converted from shadcn/ui's **Radix Nova** registry. Elixir function components use explicit attrs, slots and caller-owned state; interactive behavior uses Phoenix colocated hooks, not a React browser runtime.

Current coverage: **61 component families, 309 SSR fixtures**. React and Phoenix initial HTML are compared with strict generated-ID reference checks. SSR parity is not proof of every browser interaction; connected browser verification is also required for interactive changes.

## Development

Recommended: install [devenv](https://devenv.sh/getting-started/) and enter the declared toolchain:

```sh
devenv shell
setup-project
test-components
```

`devenv.nix` declares Bun, the Node compatibility runtime used by `tsx`, Elixir/Mix, matching Erlang/OTP, Rebar3, Bash, Git and GitHub CLI. Phoenix/Credo come from `mix.lock`; esbuild, Tailwind and the React reference dependencies come from the JavaScript package lockfile. Setup installs Hex and project dependencies explicitly; shell entry does not install them. BEAM build artifacts are isolated under devenv's state directory, avoiding conflicts with host toolchain versions.

Available shell commands:

| Command | Action |
| --- | --- |
| `setup-project` | Install Hex, fetch Mix dependencies and install Bun dependencies. |
| `generate-components` | Regenerate and format native components. |
| `check-components` | Run `mix quality`. |
| `test-components` | Run the complete generation/quality/test/parity pipeline. |
| `update-shadcn` | Refresh the live upstream registry snapshot; follow the review procedure below. |
| `preview-components` | Build assets and launch the connected preview on port 4000. |

Without devenv, provide Elixir 1.18+ (within 1.x), matching Erlang/OTP, Rebar3, Bun, the `tsx` compatibility runtime and Bash, then run `mix local.hex --force`, `mix deps.get`, `bun install` and `bun run test`. Git/GitHub CLI are needed for repository maintenance.

`bun run test` regenerates components, formats generated Elixir, checks formatting and warning-free HEEx/Elixir compilation, runs strict Credo, runs converter/comparator and ExUnit tests, builds assets, and compares all SSR fixtures. Any failed case or family exits nonzero.

```sh
mix quality                 # formatter, compiler and strict Credo
bun run generate            # local vendored source → formatted Elixir/HEEx
bun run test:parity          # asset build + React/Phoenix SSR comparison
SHADCN_PREVIEW=1 mix run --no-halt
```

Connected preview: <http://127.0.0.1:4000/live-preview/accordion>. Choose another fixture using the selector. Static, zero-JavaScript galleries are generated at `/preview/react-ssr.html` and `/preview/phoenix-ssr.html`.

Use `use ShadcnLiveview` in a Phoenix component/LiveView module to import the components. Component module docs describe controlled state and event payloads. Consumers must register the compiled colocated `hooks` with their `LiveSocket`; `assets/js/preview.js` demonstrates this integration. Build/include the project's CSS as well as the hook bundle.

## Updating from upstream shadcn/ui

### Sources of truth

| Path | Role |
| --- | --- |
| `tools/vendor.mjs` | Fetches the live Radix Nova registry and its UI component files. |
| `vendor/shadcn/registry.lock.json` | Registry URL, fetch time, dependency names and SHA-256 hashes of vendored files. |
| `vendor/shadcn/ui/`, `hooks/`, `lib/` | Committed upstream source snapshot, with local import-alias resolution. |
| `package.json`, `bun.lock` | React reference renderer, registry dependencies and conversion/build tooling. `package-lock.json` records the original npm snapshot used for the Bun migration. |
| `devenv.nix`, `devenv.yaml`, `devenv.lock` | Declared developer tools and locked Nix inputs; toolchain updates are separate from registry updates. |
| `tools/generate.tsx` | Generic source extraction, module imports and gallery generation. |
| `tools/converters/` | Native conversion rules for compound and interactive families. |
| `tools/icons.ts` | Canonical SVG extraction from Lucide. |
| `tools/fixtures.tsx`, `tools/fixtures/` | Paired React/HEEx cases and connected LiveView examples. |
| `lib/shadcn_liveview/components/`, `gallery.ex`, `lib/shadcn_liveview.ex` | Generated outputs; do not fix these by hand. |
| `lib/shadcn_liveview/helpers.ex`, `preview.ex` | Handwritten runtime helpers and connected verification app. |

The update source is the [live Radix Nova registry](https://ui.shadcn.com/r/styles/radix-nova/registry.json), not a pinned Git revision. The lock records the fetched **local content** hashes after alias resolution; it does not pin the registry server or install npm dependencies. Normal generation/tests use the committed snapshot and do **not** fetch upstream.

### Update procedure

1. **Start from a clean checkout and create an update branch.** Keep the previous Git commit as the reproducible baseline; a later registry fetch may return different content.

   ```sh
   git switch -c update/shadcn-ui
   bun run vendor
   git diff -- vendor/shadcn
   ```

   `bun run vendor` fetches all `registry:ui` entries from Radix Nova, updates source files and writes `registry.lock.json`. Review markup, style variants, exports, hooks and dependency changes. A failed fetch can leave a partial update; restore/retry it before generating or committing.

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
