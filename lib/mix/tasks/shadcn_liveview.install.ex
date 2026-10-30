defmodule Mix.Tasks.ShadcnLiveview.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc, do: "Installs shadcn_liveview into a Phoenix 1.8 application"

  @spec example() :: String.t()
  def example, do: "mix igniter.install shadcn_liveview"

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Turns a stock `mix phx.new` (Phoenix 1.8, Tailwind v4) application into a
    shadcn_liveview application. Every step is idempotent: running the task
    again changes nothing. A step whose target file no longer looks like the
    Phoenix default is skipped with a warning that describes the manual change.

    ## Example

    ```sh
    #{example()}
    # local checkout
    mix igniter.install shadcn_liveview@path:../shadcn-liveview
    # dependency already in mix.exs
    mix shadcn_liveview.install
    ```

    ## What it changes

      * `assets/css/app.css`: imports `shadcn_liveview/priv/static/shadcn.tailwind.css`
        right after `@import "tailwindcss"`, deletes Phoenix's
        `@custom-variant dark` line (the entry covers `.dark` and
        `[data-theme=dark]`) and deletes the daisyUI `@plugin` blocks.
      * daisyUI: removes the `:daisyui` dependency (Phoenix 1.8.2+) or the
        `assets/vendor/daisyui*.js` files (earlier 1.8 releases).
      * `assets/js/app.js`: imports the bundled hooks and merges them into the
        `LiveSocket` hooks after the colocated hooks.
      * `config/config.exs`: for path dependencies only, adds
        `Path.join(Mix.Project.build_path(), "lib")` to the esbuild and
        tailwind `NODE_PATH` (Hex and git dependencies resolve through `deps/`).
      * `lib/my_app_web.ex`: `html_helpers/0` keeps `import MyAppWeb.CoreComponents`
        and adds `use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]`.
      * `MyAppWeb.CoreComponents` and `MyAppWeb.Layouts` are replaced with
        shadcn-styled versions that keep Phoenix's public API (`button`,
        `input`, `table`, `header`, `list`, `icon`, `flash`, `show`/`hide`,
        `translate_error(s)`, `app`, `flash_group`, `theme_toggle`), so
        `phx.gen.html`, `phx.gen.live` and `phx.gen.auth` output keeps compiling.
      * The stock home page's daisyUI color classes become shadcn token classes.
      * The root layout's `<body>` gets the `antialiased` class that every shadcn/ui
        template assumes (Next.js layouts set it), so text renders like the originals.
      * `.credo.exs` (when present): enables the library's Credo checks
        `ShadcnLiveview.Credo.ComposerFormClears` and
        `ShadcnLiveview.Credo.ChatUsesMessageScroller` in the first config
        (`checks.enabled` if the config lists enabled checks, else `checks.extra`).
        Without `.credo.exs` the task prints the snippet instead.

    ## Options

      * `--no-core-components` - keep the existing `CoreComponents` and `Layouts`
        modules (they still use daisyUI classes; restyle them yourself or
        combine with `--keep-daisyui`).
      * `--keep-daisyui` - keep daisyUI. Its `--border` width variable clashes
        with shadcn's `--border` color token, so daisy borders render thicker.
    """
  end

  @doc """
  Where the library's files are for the user to read: Hex and git dependencies in
  `deps/`, path dependencies at their own path (relative to the working directory, or
  absolute when that is shorter).
  """
  @spec dep_path(map(), String.t()) :: String.t()
  def dep_path(deps_paths \\ Mix.Project.deps_paths(), cwd \\ File.cwd!()) do
    case deps_paths do
      %{shadcn_liveview: path} ->
        path = Path.expand(path, cwd)
        Enum.min_by([Path.relative_to(path, cwd, force: true), path], &String.length/1)

      _ ->
        "deps/shadcn_liveview"
    end
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.ShadcnLiveview.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Code.Function, as: Fun
    alias Igniter.Libs.Phoenix
    alias Igniter.Project.{Config, Deps}
    alias Igniter.Project.Module, as: ProjectModule
    alias Sourceror.Zipper

    @css_path "assets/css/app.css"
    @js_path "assets/js/app.js"
    @daisy_vendor_files ["assets/vendor/daisyui.js", "assets/vendor/daisyui-theme.js"]
    @credo_path ".credo.exs"
    @credo_checks [
      ShadcnLiveview.Credo.ComposerFormClears,
      ShadcnLiveview.Credo.ChatUsesMessageScroller
    ]

    @css_entry ~s(@import "shadcn_liveview/priv/static/shadcn.tailwind.css";)
    @hooks_import ~s(import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js")
    @library_overrides "except: [button: 1, input: 1, table: 1, icon: 1]"

    @tailwind_import ~r/^@import\s+["']tailwindcss["'][^;\n]*;[ \t]*$/m
    @phx_dark_variant ~r/^(?:\/\* Use the data attribute for dark mode\s*\*\/[ \t]*\n)?@custom-variant dark \(&:where\(\[data-theme=dark\], \[data-theme=dark\] \*\)\);[ \t]*\n(?:[ \t]*\n)?/m
    @daisy_plugin ~r/(?:^\/\*(?:[^*]|\*(?!\/))*daisy(?:[^*]|\*(?!\/))*\*\/[ \t]*\n)?^@plugin\s+["'][^"'\n]*daisyui[^"'\n]*["']\s*(?:\{[^{}]*\}|;)[ \t]*\n?(?:[ \t]*\n)?/mi
    @colocated_import ~r/^import\s*\{\s*hooks\s+as\s+colocatedHooks\s*\}\s*from\s*["']phoenix-colocated\/[^"'\n]+["'];?[ \t]*$/m
    @live_socket_import ~r/^import\s*\{\s*LiveSocket\s*\}\s*from\s*["']phoenix_live_view["'];?[ \t]*$/m
    @hooks_option ~r/\bhooks:\s*\{([^{}]*)\}/

    # Stock daisyUI fingerprints: only files that still carry them are replaced.
    @core_markers ["daisyUI", "table table-zebra", "toast toast-top toast-end"]
    @layouts_markers ["navbar", "bg-base-300", "data-phx-theme"]

    # phx.new home page classes from daisyUI themes -> shadcn token utilities.
    @home_badge {"badge badge-warning badge-sm",
                 "inline-flex h-5 items-center rounded-4xl bg-secondary px-2 py-0.5 text-xs font-medium text-secondary-foreground"}
    @home_tokens %{
      "rounded-box" => "rounded-xl",
      "bg-base-100" => "bg-background",
      "bg-base-200" => "bg-muted",
      "bg-base-300" => "bg-accent",
      "text-base-content" => "text-foreground",
      "text-base-content/70" => "text-muted-foreground",
      "text-base-content/80" => "text-muted-foreground",
      "fill-base-content" => "fill-foreground",
      "fill-base-content/40" => "fill-muted-foreground"
    }

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :shadcn_liveview,
        example: __MODULE__.Docs.example(),
        only: nil,
        schema: [core_components: :boolean, keep_daisyui: :boolean],
        defaults: [core_components: true, keep_daisyui: false]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options
      web = Phoenix.web_module(igniter)
      app = Igniter.Project.Application.app_name(igniter)
      keep_daisy? = opts[:keep_daisyui]

      igniter
      |> update_css(keep_daisy?)
      |> remove_daisy_sources(keep_daisy?)
      |> update_js()
      |> maybe_add_node_path(app)
      |> update_html_helpers(web)
      |> maybe_replace_components(web, opts[:core_components])
      |> maybe_restyle_home(web, keep_daisy?)
      |> add_body_antialiased(web)
      |> add_credo_checks()
      |> Igniter.add_notice(final_notice())
    end

    ## assets/css/app.css

    defp update_css(igniter, keep_daisy?) do
      edit_text(igniter, @css_path, fn css ->
        {css, issues} = {css, []} |> add_css_entry() |> drop_phx_dark_variant()

        if keep_daisy? do
          {css, [{:notice, daisy_kept_notice()} | issues]}
        else
          drop_daisy_plugins({css, issues})
        end
      end)
    end

    defp add_css_entry({css, issues}) do
      cond do
        String.contains?(css, "shadcn_liveview/priv/static/shadcn.tailwind.css") ->
          {css, issues}

        match = Regex.run(@tailwind_import, css, return: :index) ->
          [{start, length}] = match
          {insert_at(css, start + length, "\n" <> @css_entry), issues}

        true ->
          {css,
           [
             {:warning,
              """
              #{@css_path} has no `@import "tailwindcss"` line, so shadcn_liveview's Tailwind
              entry was not added. With a Tailwind v4 build add, right after the tailwindcss import:

                  #{@css_entry}

              Without Tailwind, serve the prebuilt stylesheet instead (README: "Use in a Phoenix app").
              """}
             | issues
           ]}
      end
    end

    defp drop_phx_dark_variant({css, issues}) do
      cond do
        Regex.match?(@phx_dark_variant, css) ->
          {Regex.replace(@phx_dark_variant, css, "", global: false), issues}

        Regex.match?(~r/^@custom-variant dark\b/m, css) ->
          {css,
           [
             {:notice,
              "#{@css_path} defines its own `@custom-variant dark`; it was kept. shadcn_liveview's " <>
                "entry already matches `.dark` and `[data-theme=dark]`, and a different dark variant " <>
                "changes some component borders."}
             | issues
           ]}

        true ->
          {css, issues}
      end
    end

    defp drop_daisy_plugins({css, issues}) do
      css = Regex.replace(@daisy_plugin, css, "")

      if String.contains?(css, "daisyui") do
        {css,
         [
           {:warning,
            "#{@css_path} still references daisyUI in a form the installer does not recognize. " <>
              "Remove the daisyUI `@plugin` entries by hand, then delete the `:daisyui` dependency " <>
              "or `assets/vendor/daisyui*.js`."}
           | issues
         ]}
      else
        {css, issues}
      end
    end

    defp daisy_kept_notice do
      "daisyUI was kept (--keep-daisyui). daisyUI's `--border` width variable clashes with " <>
        "shadcn's `--border` color token, so daisy borders render thicker; remove daisyUI when " <>
        "you no longer use its classes."
    end

    ## daisyUI dependency / vendor files

    defp remove_daisy_sources(igniter, true), do: igniter

    defp remove_daisy_sources(igniter, false) do
      if daisy_still_used?(igniter) do
        igniter
      else
        igniter
        |> remove_daisy_dep()
        |> remove_daisy_vendor_files()
      end
    end

    defp daisy_still_used?(igniter) do
      Igniter.exists?(igniter, @css_path) and
        igniter |> read_text(@css_path) |> String.contains?("daisyui")
    end

    defp remove_daisy_dep(igniter) do
      if Deps.has_dep?(igniter, :daisyui) do
        igniter
        |> Deps.remove_dep(:daisyui)
        |> Igniter.add_task("deps.unlock", ["daisyui"])
      else
        igniter
      end
    end

    defp remove_daisy_vendor_files(igniter) do
      Enum.reduce(@daisy_vendor_files, igniter, fn path, igniter ->
        if Igniter.exists?(igniter, path), do: Igniter.rm(igniter, path), else: igniter
      end)
    end

    ## assets/js/app.js

    defp update_js(igniter) do
      edit_text(igniter, @js_path, fn js ->
        with false <- String.contains?(js, "shadcn_liveview/priv/static/shadcn-hooks.js"),
             {:ok, js} <- add_hooks_import(js),
             {:ok, js} <- merge_hooks(js) do
          {js, []}
        else
          true -> {js, []}
          :error -> {js, [{:warning, manual_js_warning()}]}
        end
      end)
    end

    defp add_hooks_import(js) do
      case Regex.run(@colocated_import, js, return: :index) ||
             Regex.run(@live_socket_import, js, return: :index) do
        [{start, length}] -> {:ok, insert_at(js, start + length, "\n" <> @hooks_import)}
        nil -> :error
      end
    end

    defp merge_hooks(js) do
      case Regex.scan(@hooks_option, js, return: :index) do
        [[{start, length}, {inner_start, inner_length}]] ->
          inner = js |> binary_part(inner_start, inner_length) |> String.trim()
          inner = inner |> String.trim_trailing(",") |> String.trim()
          hooks = if inner == "", do: "...shadcnHooks", else: inner <> ", ...shadcnHooks"
          {:ok, replace_range(js, start, length, "hooks: {" <> hooks <> "}")}

        _ ->
          :error
      end
    end

    defp manual_js_warning do
      """
      #{@js_path} does not match Phoenix's default LiveSocket setup, so the hooks were not added.
      Add the import and merge the hooks after your colocated hooks:

          #{@hooks_import}

          const liveSocket = new LiveSocket("/live", Socket, {
            hooks: {...colocatedHooks, ...shadcnHooks},
            // ...
          })
      """
    end

    ## config/config.exs (path dependencies only)

    defp maybe_add_node_path(igniter, app) do
      if path_dep?(igniter) do
        Enum.reduce([:esbuild, :tailwind], igniter, &add_node_path(&2, &1, app))
      else
        igniter
      end
    end

    defp path_dep?(igniter) do
      with {:ok, dep} when is_binary(dep) <- Deps.get_dep(igniter, :shadcn_liveview),
           {:ok, quoted} <- Code.string_to_quoted(dep) do
        dep_opts =
          case quoted do
            {:shadcn_liveview, opts} when is_list(opts) -> opts
            {:{}, _, [:shadcn_liveview, _requirement, opts]} when is_list(opts) -> opts
            _ -> []
          end

        Keyword.has_key?(dep_opts, :path)
      else
        _ -> false
      end
    end

    defp add_node_path(igniter, tool, app) do
      if Config.configures_key?(igniter, "config.exs", tool, [app, :env]) do
        Config.configure(igniter, "config.exs", tool, [app, :env], nil,
          updater: &append_build_lib(&1, tool, app)
        )
      else
        igniter
      end
    end

    @build_lib ~s|Path.join(Mix.Project.build_path(), "lib")|

    defp append_build_lib(zipper, tool, app) do
      with {:ok, pair} <- Common.move_to(Zipper.subtree(zipper), &node_path_pair?/1),
           %Zipper{} = value <- pair |> Zipper.down() |> Zipper.right(),
           {:ok, value} <-
             Igniter.Code.List.append_new_to_list(
               value,
               Sourceror.parse_string!(@build_lib),
               fn item, _quoted ->
                 item |> Zipper.node() |> Sourceror.to_string() == @build_lib
               end
             ) do
        {:ok, Zipper.supertree(value)}
      else
        _ ->
          {:warning,
           """
           config/config.exs: the :#{tool} #{inspect(app)} env has no NODE_PATH list. shadcn_liveview
           is a path dependency, so add the build lib directory for its asset imports:

               env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path(), Path.join(Mix.Project.build_path(), "lib")]}
           """}
      end
    end

    defp node_path_pair?(%Zipper{node: {{:__block__, _, ["NODE_PATH"]}, _value}}), do: true
    defp node_path_pair?(_zipper), do: false

    ## lib/my_app_web.ex html_helpers/0

    defp update_html_helpers(igniter, web) do
      core = Module.concat(web, CoreComponents)

      case ProjectModule.find_and_update_module(igniter, web, &add_library_use(&1, web, core)) do
        {:ok, igniter} ->
          igniter

        {:error, igniter} ->
          Igniter.add_warning(igniter, "Could not find #{inspect(web)}. #{manual_helpers(web)}")
      end
    end

    defp add_library_use(zipper, web, core) do
      case Fun.move_to_defp(zipper, :html_helpers, 0) do
        {:ok, helpers} -> Common.within(helpers, &add_use_after_core_import(&1, web, core))
        :error -> {:warning, "#{inspect(web)} has no html_helpers/0. " <> manual_helpers(web)}
      end
    end

    defp add_use_after_core_import(helpers, web, core) do
      with :error <- find_call(helpers, :use, ShadcnLiveview),
           {:ok, import} <- find_call(helpers, :import, core) do
        {:ok, Common.add_code(import, library_use_code(), placement: :after)}
      else
        {:ok, _already_used} ->
          {:ok, helpers}

        :error ->
          {:warning,
           "#{inspect(web)}.html_helpers/0 does not import #{inspect(core)}. " <>
             manual_helpers(web)}
      end
    end

    defp find_call(zipper, name, module) do
      Fun.move_to_function_call(zipper, name, [1, 2], &Fun.argument_equals?(&1, 0, module))
    end

    defp library_use_code do
      """
      # shadcn_liveview components. CoreComponents keeps button/input/table/icon
      # with the phx.gen.* API and renders them with shadcn_liveview.
      use ShadcnLiveview, #{@library_overrides}
      """
    end

    defp manual_helpers(web) do
      "Add `use ShadcnLiveview, #{@library_overrides}` to the `html_helpers/0` quote block of " <>
        "#{inspect(web)}, next to `import #{inspect(web)}.CoreComponents`."
    end

    ## CoreComponents and Layouts

    defp maybe_replace_components(igniter, web, false) do
      Igniter.add_notice(
        igniter,
        "#{inspect(web)}.CoreComponents and #{inspect(web)}.Layouts were kept (--no-core-components). " <>
          "Their default markup uses daisyUI classes; restyle it with shadcn_liveview components."
      )
    end

    defp maybe_replace_components(igniter, web, _replace?) do
      {gettext, igniter} = gettext_backend(igniter, web)
      assigns = [web_module: inspect(web), gettext: gettext, t: translate_fun(gettext)]

      igniter
      |> replace_module(
        Module.concat(web, CoreComponents),
        "core_components.ex.eex",
        @core_markers,
        assigns
      )
      |> replace_module(Module.concat(web, Layouts), "layouts.ex.eex", @layouts_markers, assigns)
    end

    defp gettext_backend(igniter, web) do
      backend = Module.concat(web, Gettext)

      case ProjectModule.module_exists(igniter, backend) do
        {true, igniter} -> {inspect(backend), igniter}
        {false, igniter} -> {nil, igniter}
      end
    end

    defp translate_fun(nil), do: &inspect/1
    defp translate_fun(_backend), do: &"gettext(#{inspect(&1)})"

    defp replace_module(igniter, module, template, markers, assigns) do
      case ProjectModule.find_module(igniter, module) do
        {:ok, {igniter, source, _zipper}} ->
          content = Rewrite.Source.get(source, :content)
          replace_source(igniter, module, source.path, content, template, markers, assigns)

        {:error, igniter} ->
          Igniter.add_warning(igniter, "Could not find #{inspect(module)}; it was not restyled.")
      end
    end

    defp replace_source(igniter, module, path, content, template, markers, assigns) do
      cond do
        String.contains?(content, "shadcn_liveview") ->
          igniter

        Enum.all?(markers, &String.contains?(content, &1)) ->
          new_content =
            :shadcn_liveview
            |> Application.app_dir(Path.join("priv/templates/shadcn_liveview.install", template))
            |> EEx.eval_file(assigns: assigns)

          igniter
          |> Igniter.update_file(path, &Rewrite.Source.update(&1, :content, new_content))
          |> Igniter.format([path])

        true ->
          Igniter.add_warning(
            igniter,
            "#{inspect(module)} (#{path}) differs from Phoenix's default, so it was not replaced. " <>
              "Its daisyUI classes need restyling; see #{template_hint(template)}."
          )
      end
    end

    defp template_hint(template) do
      "#{__MODULE__.Docs.dep_path()}/priv/templates/shadcn_liveview.install/#{template}"
    end

    ## Stock home page

    defp maybe_restyle_home(igniter, _web, true), do: igniter

    defp maybe_restyle_home(igniter, web, false) do
      path =
        igniter
        |> ProjectModule.proper_location(web)
        |> Path.rootname()
        |> Path.join("controllers/page_html/home.html.heex")

      if Igniter.exists?(igniter, path) do
        edit_text(igniter, path, &{restyle_home(&1), []})
      else
        igniter
      end
    end

    defp restyle_home(heex) do
      {badge, badge_classes} = @home_badge

      heex
      |> String.replace(badge, badge_classes)
      |> then(
        &Regex.replace(~r/class="([^"]*)"/, &1, fn _, classes ->
          ~s(class="#{map_home_tokens(classes)}")
        end)
      )
    end

    defp map_home_tokens(classes) do
      classes
      |> String.split(" ")
      |> Enum.map_join(" ", fn token ->
        {variants, base} = split_variants(token)
        variants <> Map.get(@home_tokens, base, base)
      end)
    end

    defp split_variants(token) do
      case String.split(token, ":") |> Enum.split(-1) do
        {[], [base]} -> {"", base}
        {variants, [base]} -> {Enum.join(variants, ":") <> ":", base}
      end
    end

    ## Root layout <body class="antialiased">

    @body_tag ~r/<body\b([^>]*)>/

    defp add_body_antialiased(igniter, web) do
      path =
        igniter
        |> ProjectModule.proper_location(web)
        |> Path.rootname()
        |> Path.join("components/layouts/root.html.heex")

      if Igniter.exists?(igniter, path) do
        edit_text(igniter, path, &body_antialiased(&1, path))
      else
        igniter
      end
    end

    defp body_antialiased(heex, path) do
      case Regex.run(@body_tag, heex, return: :index) do
        [{start, length}, {attrs_start, attrs_length}] ->
          attrs = binary_part(heex, attrs_start, attrs_length)

          case body_attrs(attrs) do
            {:ok, ^attrs} -> {heex, []}
            {:ok, attrs} -> {replace_range(heex, start, length, "<body" <> attrs <> ">"), []}
            :error -> {heex, [{:warning, body_warning(path)}]}
          end

        nil ->
          {heex, [{:warning, body_warning(path)}]}
      end
    end

    defp body_attrs(attrs) do
      case Regex.run(~r/(?<![\w-])class="([^"]*)"/, attrs, return: :index) do
        [_, {start, length}] ->
          classes = binary_part(attrs, start, length)

          if "antialiased" in String.split(classes),
            do: {:ok, attrs},
            else:
              {:ok, replace_range(attrs, start, length, String.trim("antialiased " <> classes))}

        nil ->
          if attrs =~ ~r/(?<![\w-])class=/,
            do: :error,
            else: {:ok, ~s( class="antialiased") <> attrs}
      end
    end

    defp body_warning(path) do
      "#{path}: add the `antialiased` class to <body> by hand (shadcn/ui templates assume it)."
    end

    ## .credo.exs

    defp add_credo_checks(igniter) do
      if Igniter.exists?(igniter, @credo_path) do
        config = read_text(igniter, @credo_path)

        case Enum.reject(@credo_checks, &String.contains?(config, inspect(&1))) do
          [] -> igniter
          missing -> Igniter.update_elixir_file(igniter, @credo_path, &enable_checks(&1, missing))
        end
      else
        Igniter.add_notice(igniter, """
        Credo checks: shadcn_liveview ships #{Enum.map_join(@credo_checks, " and ", &inspect/1)}
        (chat composers that keep the sent text, chat threads that don't follow new messages).
        With Credo installed, run `mix credo gen.config` and rerun this task, or add to your config:

            checks: %{extra: #{credo_entries_code(@credo_checks)}}

        If Credo was added after shadcn_liveview was compiled: `mix deps.compile shadcn_liveview --force`.
        """)
      end
    end

    defp enable_checks(zipper, checks) do
      entries = Enum.map(checks, &Sourceror.parse_string!("{#{inspect(&1)}, []}"))

      with {:ok, root} <- Common.move_to(zipper, &match?({:%{}, _, _}, &1.node)),
           {:ok, configs} <- map_value(root, :configs),
           {:ok, config} <-
             Igniter.Code.List.move_to_list_item(configs, &match?({:%{}, _, _}, &1.node)),
           {:ok, zipper} <-
             Igniter.Code.Map.set_map_key(
               config,
               :checks,
               Sourceror.parse_string!("%{extra: #{credo_entries_code(checks)}}"),
               &add_to_checks(&1, entries)
             ) do
        {:ok, zipper}
      else
        _ ->
          {:warning,
           "#{@credo_path} has no `configs: [%{...}]` map to extend; add `#{credo_entries_code(@credo_checks)}` to its checks by hand."}
      end
    end

    # `checks: %{enabled: [...]}` runs only the listed checks; otherwise `extra` adds to the defaults.
    defp add_to_checks(checks, entries) do
      cond do
        Igniter.Code.List.list?(checks) ->
          append_all(checks, entries)

        match?({:%{}, _, _}, checks.node) ->
          key = if map_value(checks, :enabled) == :error, do: :extra, else: :enabled
          Igniter.Code.Map.set_map_key(checks, key, entries, &append_all(&1, entries))

        true ->
          :error
      end
    end

    defp append_all(list, entries) do
      Enum.reduce_while(entries, {:ok, list}, fn entry, {:ok, list} ->
        case Igniter.Code.List.append_new_to_list(list, entry) do
          {:ok, list} -> {:cont, {:ok, list}}
          :error -> {:halt, :error}
        end
      end)
    end

    defp map_value(map, key) do
      with %Zipper{} = first <- Zipper.down(map),
           {:ok, pair} <- Common.move_right(first, &key?(&1, key)) do
        Igniter.Code.Tuple.tuple_elem(pair, 1)
      else
        _ -> :error
      end
    end

    defp key?(item, key) do
      with true <- Igniter.Code.Tuple.tuple?(item),
           {:ok, item_key} <- Igniter.Code.Tuple.tuple_elem(item, 0) do
        Common.nodes_equal?(item_key, key)
      else
        _ -> false
      end
    end

    defp credo_entries_code(checks),
      do: "[" <> Enum.map_join(checks, ", ", &"{#{inspect(&1)}, []}") <> "]"

    ## Notices and helpers

    defp final_notice do
      """
      shadcn_liveview is installed.

        * `<.button>`, `<.input>`, `<.table>` and `<.icon>` are your CoreComponents wrappers
          (Phoenix API, shadcn markup); every other shadcn_liveview component comes from
          `use ShadcnLiveview` in html_helpers/0.
        * Agent rules: #{__MODULE__.Docs.dep_path()}/usage-rules.md (sync them with `usage_rules`).
        * Rebuild assets (`mix assets.build`) or restart `mix phx.server`.
      """
    end

    defp edit_text(igniter, path, transform) do
      if Igniter.exists?(igniter, path) do
        igniter = Igniter.include_existing_file(igniter, path)
        content = read_text(igniter, path)
        {new_content, issues} = transform.(content)

        igniter =
          if new_content == content do
            igniter
          else
            Igniter.update_file(igniter, path, &Rewrite.Source.update(&1, :content, new_content))
          end

        Enum.reduce(issues, igniter, fn
          {:warning, message}, igniter -> Igniter.add_warning(igniter, message)
          {:notice, message}, igniter -> Igniter.add_notice(igniter, message)
        end)
      else
        Igniter.add_warning(
          igniter,
          "#{path} was not found; follow usage-rules/phoenix.md by hand."
        )
      end
    end

    defp read_text(igniter, path) do
      igniter
      |> Igniter.include_existing_file(path)
      |> Map.fetch!(:rewrite)
      |> Rewrite.source!(path)
      |> Rewrite.Source.get(:content)
    end

    defp insert_at(text, index, insertion) do
      binary_part(text, 0, index) <>
        insertion <> binary_part(text, index, byte_size(text) - index)
    end

    defp replace_range(text, start, length, replacement) do
      binary_part(text, 0, start) <>
        replacement <> binary_part(text, start + length, byte_size(text) - start - length)
    end
  end
else
  defmodule Mix.Tasks.ShadcnLiveview.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'shadcn_liveview.install' requires igniter. Add it and try again:

          mix igniter.install shadcn_liveview

      or follow the manual steps in #{__MODULE__.Docs.dep_path()}/usage-rules/phoenix.md.
      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
