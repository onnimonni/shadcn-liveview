# Installing shadcn_liveview in a Phoenix 1.8 (`mix phx.new`) app

## Installer (use this first)

```sh
mix igniter.install shadcn_liveview            # Hex
mix igniter.install shadcn_liveview@path:../shadcn-liveview   # local checkout
mix shadcn_liveview.install                    # dep (and igniter) already in mix.exs
```

`mix igniter.install` comes from the `igniter_new` archive (`mix archive.install hex igniter_new`).
The installer applies every step of the manual recipe below, removes daisyUI, and replaces the
app's daisyUI `CoreComponents` and `Layouts` with shadcn-styled versions. Re-running it changes
nothing; files that differ from the Phoenix defaults are skipped with a printed manual step.
It also adds Credo (`only: [:dev, :test]`) when missing and enables this library's two Credo
checks (a new `.credo.exs` keeps Credo's defaults and lists them under `checks.extra`), and adds
`usage_rules` (`only: [:dev]`) plus a `usage_rules:` config in `mix.exs`, then runs
`mix usage_rules.sync`: these rules land in `AGENTS.md` (phx.new's `phoenix:*` sections are
kept) and the `shadcn-template-to-liveview` skill in `.claude/skills/`. Rerun
`mix usage_rules.sync` after upgrading shadcn_liveview.
Flags: `--no-core-components` (keep your CoreComponents/Layouts), `--keep-daisyui`,
`--no-credo`, `--no-usage-rules`.
If `mix igniter.install` fails in an already-compiled app with `protocol Enumerable not
implemented for type Rewrite` (an Igniter protocol-consolidation issue; nothing but the
`:igniter` dep is written), run `mix deps.get && mix compile && mix shadcn_liveview.install`.

What you get afterwards:

- `<body>` in the root layout has `antialiased`, which every shadcn template assumes; without it
  text renders visibly heavier than the originals.
- `html_helpers/0` has `import MyAppWeb.CoreComponents` plus
  `use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]`.
- `<.button>`, `<.input>`, `<.table>`, `<.icon>` are the app's CoreComponents wrappers: Phoenix's
  API (what `phx.gen.html`/`phx.gen.live`/`phx.gen.auth` templates emit) rendered with this
  library. `<.button>` maps `variant="primary"` to shadcn `default`, no variant to `outline`,
  and also accepts every shadcn `variant`/`size`. `<.input>` renders `field`/`field_label`/
  `field_error` around the library `input`, `native_select`, `textarea`, or a native checkbox,
  and shows errors only after `used_input?/1`. A `class` on these wrappers is appended to the
  shadcn classes (it no longer replaces them as in stock CoreComponents).
- Everything else (`dialog`, `card`, `form_field`, `switch`, …) comes from `use ShadcnLiveview`.
  Call the library versions of the four wrapped names by module:
  `<ShadcnLiveview.Components.Button.button>`, `<ShadcnLiveview.Components.Input.input>`.
- `header`, `list`, `flash`, `Layouts.app`, `flash_group` and `theme_toggle` keep their names and
  attributes and use shadcn tokens; the stock `data-theme` toggle switches the library's dark mode.

Hand-written UI may use either the wrappers or the library components with `form_field`
(see forms.md); generated code keeps using the wrappers.

With Credo added by hand later, run `mix deps.compile shadcn_liveview --force`: the checks only
compile when Credo is loaded, and Mix does not rebuild shadcn_liveview by itself.

## Manual recipe

Verified against a stock `mix phx.new` app (Phoenix 1.8.14, LiveView 1.2.12, Tailwind 4,
daisyUI 5): compiles with `--warnings-as-errors`, `mix precommit` passes, hooks and styles work
in dev and in `MIX_ENV=prod mix assets.deploy` output. No Node/React install is needed.

### 1. Dependency

```elixir
{:shadcn_liveview, "~> 0.1"}
```

Path dependencies (`path: "../shadcn-liveview"`) are not copied into `deps/`. For those, add the
build lib directory to `NODE_PATH` in **both** the `:esbuild` and `:tailwind` profiles in
`config/config.exs`. Hex and git dependencies need no config change.

```elixir
env: %{
  "NODE_PATH" => [
    Path.expand("../deps", __DIR__),
    Mix.Project.build_path(),
    Path.join(Mix.Project.build_path(), "lib")
  ]
}
```

### 2. Assets (bundled, as Phoenix's AGENTS.md requires)

`assets/css/app.css`, directly after the Tailwind import, import the **Tailwind source entry**
(not the prebuilt `shadcn.css`):

```css
@import "tailwindcss" source(none);
@import "shadcn_liveview/priv/static/shadcn.tailwind.css";
```

Then delete phx.new's `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));`
line; the entry's dark variant covers `.dark` and `[data-theme=dark]`, and keeping phx.new's
line changes some dark-mode borders.

The entry compiles the components' classes into your own Tailwind build: one preflight, one
theme, one utilities layer. So your classes on components win without `!`
(`<.input class="pl-8">`, `table_cell class="hidden md:table-cell"`), and token utilities such as
`bg-primary/10`, `ring-primary` or `text-muted-foreground` work anywhere in app markup. It sets
`--font-sans`, the radius scale and the color names (`primary`, `muted`, `sidebar-*`, …) to
shadcn's meaning. Never import both `shadcn.tailwind.css` and `shadcn.css`: the prebuilt file's
own utilities layer would override your classes.

`assets/js/app.js`, merged after your colocated hooks:

```js
import {hooks as colocatedHooks} from "phoenix-colocated/my_app"
import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...shadcnHooks},
})
```

Do not use `../../deps/...` relative paths (they break for path deps) and do not import
`phoenix-colocated/shadcn_liveview` (the carousel hook's Embla import cannot resolve there).
Apps without a bundler can serve `priv/static` with `Plug.Static` instead (see README).

### 3. CoreComponents coexistence

`CoreComponents` and this library both define `button/1`, `input/1`, `table/1` and `icon/1`.
Plain `import CoreComponents` plus `use ShadcnLiveview` fails with an ambiguous-call error.
Pick one of these in `html_helpers/0` of `lib/my_app_web.ex`:

```elixir
# Recommended for hand-written UI. shadcn icon/1 renders `hero-*` names exactly like
# CoreComponents (phx.new's Heroicons plugin) and everything else from its Lucide set.
import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1, icon: 1]
use ShadcnLiveview
```

```elixir
# The installer uses this variant and rewrites CoreComponents over the library.
# Keep phx.gen.* templates compiling (they pass variant="primary", <.input label=...>,
# <.table rows=...>): keep CoreComponents names and call shadcn ones by module.
import MyAppWeb.CoreComponents
use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]
alias ShadcnLiveview.Components.{Button, Input, Table, Icon}
# <Button.button variant="outline">…</Button.button>, <Icon.icon name="plus" />
```

With the first variant both `<.icon name="hero-x-mark">` (layouts, flash) and
`<.icon name="plus">` (Lucide) work.
With these manual variants, this library's rules replace Phoenix's "always use `<.input>` from
core_components" rule: use `<.form_field :let={a} field={@form[:x]} label="X"><.input {a} /></.form_field>`.
After `mix shadcn_liveview.install`, `<.input>` is the CoreComponents wrapper instead: write
`<.input field={@form[:x]} label="X" />`, or call `ShadcnLiveview.Components.Input.input` inside
`form_field`.
The flash, header, list, show/hide and layout helpers do not collide.

### 4. Dark mode and daisyUI

- Phoenix 1.8 switches themes with `data-theme`; shadcn tokens follow both `.dark` and
  `[data-theme=dark]` on `<html>`, so the stock theme toggle works.
- shadcn's `--border` is a color, daisyUI's `--border` is a width. Keeping daisyUI makes its
  `.btn`/`.alert` borders thicker and drops some daisy badge padding. Recommended: delete the
  two daisyUI `@plugin` blocks from `app.css` and use one design system. phx.new's generated
  layouts and flash still render (they use Tailwind utilities and `hero-*` icons).
- shadcn's base layer sets `body` background/foreground and default border/outline colors.
- Color utilities (`bg-primary`, `text-accent`, …) use shadcn's token meaning with any opacity
  modifier. Theme by overriding the tokens (`--primary`, `--radius`, …) in `:root` and
  `[data-theme=dark]` in your own CSS.
