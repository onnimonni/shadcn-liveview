# Working on shadcn-liveview

<!-- githits -->
GitHits is installed for public OSS/package evidence. Prefer the `githits-mcp` skill when available; otherwise call GitHits `quick_start` once before choosing tools.
<!-- githits -->

Use the relevant Elixir/Phoenix skills for component implementation and review.
These rules come from verified browser findings; they describe required behavior,
not fixes that have already been implemented.

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
   LiveView; it does not automatically honor `phx-target`. Propagate a caller's
   target to the element owning the hook and use `pushEventTo(target, event,
   payload)` when a target is supplied, falling back to `pushEvent` otherwise.
   Support LiveComponent CIDs such as `@myself` as well as selectors. Follow the
   routing pattern in accordion/tabs and `tools/converters/linked.ts`. Verify
   delivery inside a LiveComponent whose parent does not handle its event.
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
  The six findings above reproduced despite all 50 existing tests passing and
  compilation succeeding with warnings treated as errors.
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
