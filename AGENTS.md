# Working on shadcn-liveview

<!-- githits -->
GitHits is installed for public OSS/package evidence. Prefer the `githits-mcp` skill when available; otherwise call GitHits `quick_start` once before choosing tools.
<!-- githits -->

Use the relevant Elixir/Phoenix skills for component implementation and review.
These rules are regression contracts from verified browser findings, not a list
of currently unfixed bugs. Inspect the current implementation before changing it;
verify the affected consumer behavior rather than re-fixing a historical issue.

## Never manually edit generated LiveView components

**MUST NOT manually edit `lib/shadcn_liveview/components/*.ex`,
`lib/shadcn_liveview/gallery.ex`, or `lib/shadcn_liveview.ex`.**
This prohibition includes temporary fixes, hooks, CSS, markup, and documentation
inside generated files. Change the owning source in `tools/generate.tsx`,
`tools/generator/`, `tools/converters/`, or `tools/fixtures/` (including
`tools/fixtures.tsx`), then regenerate with `bun run generate`.
Inspect generated output, but never patch it by hand. Preserve existing user
changes when regenerating. Shared hook fixes must cover every emitted family
using that hook, not just the component where the bug was first observed.

## Component behavior rules

1. **Preserve uncontrolled values across patches.** `default_checked` and
   `default_value` initialize local state; unrelated class, layout, or disabled
   patches must retain the user's selection. Distinguish controlled and
   uncontrolled modes explicitly. Reconcile controlled values deliberately
   instead of blindly reading initial server attributes in every `updated()`.
   If `beforeUpdate()` restores server-owned markup, preserve and reapply the
   correct local state afterward. Keep mounted reset defaults separate from
   current values. Check both visible state and native submitted values for
   checkbox, switch, and slider. See [issue #1](https://github.com/onnimonni/shadcn-liveview/issues/1)
   and `tools/converters/controls.ts`.

2. **Honor event targets in hooks.** `this.pushEvent()` sends to the owning
   LiveView; it does not automatically honor `phx-target`. Honor an explicit hook
   root target and the nearest inherited `phx-target`, using `pushEventTo(target,
   event, payload)` when supplied and `pushEvent` otherwise. Support LiveComponent
   CIDs such as `@myself` as well as selectors. Preserve reply callbacks and push
   promises when the caller uses them. Emit the shared `sendEventMethod` from
   `tools/converters/hook-events.ts`; never call `pushEvent`/`pushEventTo`
   directly. LiveView rejects hook pushes while disconnected, so the helper
   pre-handles failures; hooks with optimistic server-controlled state chain
   `.catch` to restore it. Verify delivery inside a LiveComponent whose
   parent does not handle its event.
   See [issue #2](https://github.com/onnimonni/shadcn-liveview/issues/2).

3. **Render textarea values as escaped text content.** A `<textarea value="…">`
   attribute does not populate the control. Normalize a dedicated value assign
   and render it between the tags, defining precedence relative to the content
   slot. Avoid template whitespace that creates a nonempty default value. Apply
   this to both `textarea` and `input_group_textarea`; verify initial values,
   server updates, empty values, escaping, and form serialization. See
   [issue #3](https://github.com/onnimonni/shadcn-liveview/issues/3) and the native
   control rendering in `tools/generate.tsx`.

4. **Propagate disabled state to native controls.** Compute effective disabled
   state from both the child and root context, for example
   `@disabled || @context.disabled`, and apply it to the native input and related
   controls. `data-disabled` and ARIA attributes alone do not prevent editing,
   focus, or submission. Verify root-only disabled, child-only disabled, and
   enabling/disabling through a server patch. See
   [issue #4](https://github.com/onnimonni/shadcn-liveview/issues/4) and the
   combobox converter in `tools/converters/command.ts`.

5. **Scope delegated events to the nearest owning root.** Containment checks
   such as `this.el.contains(trigger)` also accept nested component triggers.
   Require the matching trigger's nearest family root to equal `this.el`; for
   collapsibles, use
   `trigger.closest('[data-slot="collapsible"]') === this.el`. Scope descendant
   queries similarly so nested widgets keep independent state. Verify that an
   inner click or keypress emits only the inner component's event. See
   [issue #5](https://github.com/onnimonni/shadcn-liveview/issues/5) and
   `tools/converters/controls.ts`.

6. **Complete browser behavior after SSR.** Reproducing upstream initial HTML
   is insufficient when upstream effects later enable interaction. ScrollArea
   must allow user scrolling on supported axes once connected; permanent
   `overflow:hidden` leaves long content inaccessible. Enable native overflow
   or supply the corresponding hook lifecycle if initial SSR parity requires
   it. Verify with content taller/wider than the viewport and actual user
   scrolling, not only programmatic `scrollTop` changes. See
   [issue #6](https://github.com/onnimonni/shadcn-liveview/issues/6) and the
   ScrollArea rendering in `tools/generate.tsx`.

## Verification for component changes

- Run the project's checks for implementation changes: `bun run test`
  regenerates components, runs `mix quality`, tool tests, ExUnit, and SSR parity.
  Use targeted checks during development and inspect regeneration changes.
- Add connected browser regressions for changed hook behavior. Render-only
  ExUnit tests and SSR parity cannot prove JavaScript lifecycle correctness.
  Earlier findings reproduced despite passing tests and strict compilation;
  test counts are not evidence of connected behavior.
- Build assets with `mix assets.build`, then run
  `SHADCN_PREVIEW=1 mix run --no-halt` and open
  `http://127.0.0.1:4000/live-preview/<fixture>` for connected preview checks.
  Use a focused LiveView/LiveComponent harness when existing fixtures omit the
  failure case.
- Match browser checks to the changed behavior: interact, trigger an unrelated
  patch, inspect native values or `FormData`, and exercise reset when relevant.
  Include targeted event delivery, nested ownership, inherited disabled state,
  or genuinely overflowing content for the corresponding families. Wait for
  observable connection/patch results rather than arbitrary timing delays.
- Report checks actually run and any remaining gaps. Passing initial-render
  parity does not establish complete runtime behavior.
- `test/browser/console-errors.spec.ts` (part of `bun run test:browser`) opens every
  connected fixture, interacts connected and then with the socket disconnected, and fails on
  any console error, uncaught exception, unhandled rejection, failed request or HTTP ≥400.
  Never silence a component's console output to make it pass; fix the hook.

## Building consumer applications

**Read `usage-rules.md` first**, then the topic file you need under `usage-rules/`
(`components.md` index, `phoenix.md`, `forms.md`, `overlays.md`, `data-tables.md`).
These files ship in the Hex package and are what consumers' agents see; this
section intentionally does not duplicate them. Runnable references:
`examples/consumer` (storefront, settings). Run consumer Mix commands inside the
example; its scripts isolate `MIX_BUILD_ROOT`.

Set up every new Phoenix app (inside or outside this repository) with the bundled
installer instead of wiring assets by hand: `mix phx.new my_app`, then
`mix igniter.install shadcn_liveview@path:<path to this checkout>` (Hex apps:
`mix igniter.install shadcn_liveview`). It needs the `igniter_new` archive
(`mix archive.install hex igniter_new`); `usage-rules/phoenix.md` explains the result.

Creating a new example app inside this repository (verified by agent runs):
- Install `phx_new`/`igniter_new` archives in isolation (see the next bullet) and use a
  `MIX_BUILD_ROOT` under `/private/tmp`, not the `/tmp` symlink, for apps outside the repo.
- The `~/.mix` `phx_new` archive may crash under the devenv Elixir (`Regex.safe_run`
  FunctionClauseError). Install a matching one in isolation:
  `MIX_ARCHIVES=/tmp/phx-archives mix archive.install hex phx_new 1.8.14 --force`.
- On macOS the downloaded Tailwind binary can be SIGKILLed (exit 137) until re-signed:
  `codesign --force --sign - _build/tailwind-macos-arm64-*`.
- The root `package.json` is `"type": "module"`; add `assets/package.json` with
  `{"type": "commonjs"}` so esbuild accepts phx.new's CommonJS `assets/vendor/topbar.js`.
- Path dependencies compile `gallery.ex`/preview modules (slow first build); the Hex package
  excludes them.

## Converting shadcn/ui templates (consumer + maintainer)

Consumers' agents convert React blocks/examples with `priv/shadcn-to-liveview.mjs` and the skill
`usage-rules/skills/shadcn-template-to-liveview/SKILL.md` (also the workflow to follow when asked to
port a template in this repo: `bunx tsx tools/template-to-liveview/cli.ts <input> --module ...`).

- Source: `tools/template-to-liveview/` (TypeScript, @babel/parser). `tools/build-assets.sh`
  bundles it into `priv/shadcn-to-liveview.mjs` (Hex package file, not committed).
- The component API is read at runtime from `lib/shadcn_liveview/components/*.ex` with the same
  parser as `usage-rules/components.md`; only structural recipes live in `families.ts`. When a
  family's composition changes (slots, `:let` contexts, default events), update `families.ts`
  and `convert.ts`; `bun run test:tools` checks the recipe tables against the metadata and
  converts vendored blocks/examples (dashboard-01, sidebar-07 and chart-example included).
- Evaluate changes against an agent, not just the tests: pick blocks the converter was not
  tuned on, have Codex/Claude convert them headlessly in a worktree from the brief pattern in
  the history of this file's change, and compare against React renders with Playwright. The
  first such run (dashboard-01, sidebar-07, login-04) drove placeholder TODOs, identity
  events, JSON imports, source-completeness rows, `@is_mobile` and chart conversion.
- End-to-end check: convert into a fresh `mix phx.new` + installer app (isolated
  `MIX_BUILD_ROOT` under `/private/tmp`), route the modules, `mix compile --warnings-as-errors`
  and a LiveViewTest that mounts every route.

## Maintaining the agent-facing docs

- `usage-rules/components.md` is generated by `bun run generate`
  (`tools/generator/component-index.ts`); `bun run test:tools` fails when stale.
  Improve it through moduledocs, attr `values:`/`doc:` and the generator.
- `usage-rules.md` and the other `usage-rules/*.md` are hand-written. Every
  snippet must compile against the current API and every behavioral claim must
  be verified in a connected browser or a stock `mix phx.new` app; update them in
  the same change as the API or behavior they describe.
- Add library facts discovered while building apps (bugs, workarounds, payload
  shapes) to the owning moduledoc or usage rule, not only to issue comments.

## Maintaining ShadcnLiveview.DataTable

`lib/shadcn_liveview/data_table.ex` and `data_table/state.ex` are hand-written (upstream has no
data-table component; TanStack Table is the React reference). `use ShadcnLiveview` imports its
four components through `@extra_imports` in `tools/generate.tsx`; the component index and the
converter metadata read `data_table.ex` like `form.ex`. Keep its control ids
(`<id>-select-all`, `<id>-row-<row>-select`, `<id>-row-<row>-actions`, `<id>-columns`) and
payloads in sync with `handle_event/2`, `usage-rules/data-tables.md` and the converter's
TanStack recipe (`tools/template-to-liveview/tanstack.ts` + the DataTable section of
`convert.ts`). Connected harness: `/data-table-preview` (`preview_data_table.ex`, a URL-backed
table plus a LiveComponent table); regressions: `test/data_table_test.exs`,
`test/browser/data_table_test.exs`.

## Maintaining the consumer Credo checks

`lib/shadcn_liveview/credo/*.ex` are hand-written Credo checks shipped to consumers
(`ShadcnLiveview.Credo.ComposerFormClears`, `ShadcnLiveview.Credo.ChatUsesMessageScroller`,
plus the shared `ShadcnLiveview.Credo.Heex` template scanner). They compile only when Credo
is loaded (`credo` is an optional dependency), so keep every module inside
`if Code.ensure_loaded?(Credo.Check)`.

- Keep them in sync with the `message`, `bubble` and `message_scroller` APIs: component
  names in their `param_defaults`, and the fix snippets in the issue messages and
  explanations (`message_scroller_provider auto_scroll default_scroll_position`,
  `message_scroller id/context`, `message_scroller_viewport context`,
  `message_scroller_content`, `message_scroller_item message_id`). Rename or attr changes
  there must update the checks, their tests and the chat bullet in `usage-rules.md`.
- The composer fix is browser-verified: only a per-message id on the text control clears
  it (a per-message form id alone does not, because LiveView finds the input by its own
  id). Re-verify in a connected browser before changing that advice.
- Test: `mix test test/credo/chat_checks_test.exs`. To run them for real, add the checks to
  an app's `.credo.exs` with this checkout as a path dependency and run
  `mix credo --strict`; when doing that from this repo's devenv shell, first
  `export MIX_BUILD_ROOT="$PWD/_build"` in the app so its build does not land in this
  repo's shared build directory.

## Maintaining the Phoenix installer

`lib/mix/tasks/shadcn_liveview.install.ex` and
`priv/templates/shadcn_liveview.install/*.eex` are hand-written (not generated).
The templates mirror Phoenix's generated `CoreComponents`/`Layouts` API and the task
recognizes stock files by daisyUI fingerprints, so re-verify them against every new
`phx.new` release:

1. Regenerate the stock fixtures from the new version and copy the same file list over
   `test/fixtures/phx_new/` (the generated `AGENTS.md` stays out of the fixtures: its class
   examples would leak into the preview CSS build; update the marker skeleton `@agents` in
   the installer test instead):
   `MIX_ARCHIVES=/tmp/phx-archives mix archive.install hex phx_new <version> --force`, then
   `MIX_ARCHIVES=/tmp/phx-archives mix phx.new my_app --database sqlite3 --no-install` in
   `/private/tmp`.
2. `mix test test/mix/tasks/shadcn_liveview_install_test.exs` (patches, idempotency, flags,
   skip warnings, Credo/usage_rules config, and rendering of the generated CoreComponents).
3. In a fresh installed `mix phx.new --database sqlite3` app: `mix igniter.install
   shadcn_liveview@path:<checkout> --yes` (twice: the second run must change nothing),
   `mix phx.gen.live Accounts User users name:string age:integer active:boolean bio:text`,
   `mix compile --warnings-as-errors`, `mix precommit`, `mix assets.build` and
   `MIX_ENV=prod mix assets.deploy`, then browser-check the generated pages at 390px and
   1280px (forms with errors, flash, table, theme toggle, no daisyUI classes).
4. Credo and usage_rules integration, on new Credo, usage_rules or phx.new versions: in that
   app, `AGENTS.md` must still hold phx.new's `phoenix:*` sections plus the inlined
   `shadcn_liveview` section and links to the `shadcn_liveview:*` sub-rules, and
   `.claude/skills/shadcn-template-to-liveview/SKILL.md` must exist. Add a looped
   `<.bubble :for=...>` inside a `max-h-96 overflow-y-auto` div to a LiveView: `mix credo
   --strict` must report it next to Credo's default checks (e.g. an `IO.inspect` call).
   Re-check the usage_rules config keys (`sub_rules`, `main`, `link`,
   `skills: [package_skills: ...]`, the default `.claude/skills` location) against its
   README and the Credo `checks: %{extra: ...}` shape against Credo's config docs.

`mix quality` runs `mix usage_rules.validate` over `usage-rules.md`, `usage-rules/*.md` and the
package skill: references such as `Module.fun/arity` must resolve against documented API, so
write fully qualified module names in the rules.
