defmodule Mix.Tasks.ShadcnLiveview.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import Phoenix.Component, only: [to_form: 2]
  alias ShadcnLiveview.Components.Input

  # phx.new 1.8.14's AGENTS.md with the guideline bodies elided: the full text holds Tailwind
  # class examples that the repo's preview CSS build would pick up from test/fixtures.
  @agents """
  This is a web application written using the Phoenix web framework.

  ## Project guidelines

  <!-- usage-rules-start -->

  <!-- phoenix:elixir-start -->
  ## Elixir guidelines
  <!-- phoenix:elixir-end -->

  <!-- phoenix:phoenix-start -->
  ## Phoenix guidelines
  <!-- phoenix:phoenix-end -->

  <!-- phoenix:ecto-start -->
  ## Ecto Guidelines
  <!-- phoenix:ecto-end -->

  <!-- phoenix:html-start -->
  ## Phoenix HTML guidelines
  <!-- phoenix:html-end -->

  <!-- phoenix:liveview-start -->
  ## Phoenix LiveView guidelines
  <!-- phoenix:liveview-end -->

  <!-- usage-rules-end -->
  """

  # Files from an unmodified `mix phx.new my_app --database sqlite3` (Phoenix 1.8.14).
  @fixture_root Path.expand("../../fixtures/phx_new", __DIR__)
  @fixtures @fixture_root
            |> Path.join("**/*")
            |> Path.wildcard(match_dot: true)
            |> Enum.reject(&File.dir?/1)
            |> Map.new(&{Path.relative_to(&1, @fixture_root), File.read!(&1)})
            |> Map.put("AGENTS.md", @agents)

  @css "assets/css/app.css"
  @js "assets/js/app.js"
  @web "lib/my_app_web.ex"
  @core "lib/my_app_web/components/core_components.ex"
  @layouts "lib/my_app_web/components/layouts.ex"
  @home "lib/my_app_web/controllers/page_html/home.html.heex"
  @root "lib/my_app_web/components/layouts/root.html.heex"

  defp project(overrides \\ %{}, opts \\ []) do
    deps = Keyword.get(opts, :dep, ~s({:shadcn_liveview, "~> 0.1"}))

    files =
      @fixtures
      |> Map.update!(
        "mix.exs",
        &String.replace(&1, "{:bandit, \"~> 1.5\"}", "{:bandit, \"~> 1.5\"},\n      #{deps}")
      )
      |> Map.merge(overrides)
      |> Map.reject(fn {_path, content} -> is_nil(content) end)

    test_project(app_name: :my_app, files: files)
  end

  defp install(igniter, argv \\ []) do
    Igniter.compose_task(igniter, Mix.Tasks.ShadcnLiveview.Install, argv)
  end

  defp content(igniter, path) do
    igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)
  end

  describe "stock phx.new app" do
    setup do
      %{igniter: project() |> install()}
    end

    test "imports the Tailwind entry and removes daisyUI and the phx dark variant", %{
      igniter: igniter
    } do
      css = content(igniter, @css)

      assert css =~
               """
               @import "tailwindcss" source(none);
               @import "shadcn_liveview/priv/static/shadcn.tailwind.css";
               @import "phoenix-colocated/my_app/colocated.css";
               """

      refute css =~ ~r/daisy/i
      refute css =~ "@custom-variant dark"
      assert css =~ ~s(@plugin "../vendor/heroicons";)
      assert css =~ "@custom-variant phx-click-loading"
      refute css =~ ~r/\n{3,}/

      igniter
      |> assert_has_patch("mix.exs", """
      - |      {:daisyui,
      """)
      |> assert_has_task("deps.unlock", ["daisyui"])
    end

    test "registers the bundled hooks after the colocated hooks", %{igniter: igniter} do
      assert_has_patch(igniter, @js, """
       |import {hooks as colocatedHooks} from "phoenix-colocated/my_app"
      + |import {hooks as shadcnHooks} from "shadcn_liveview/priv/static/shadcn-hooks.js"
      """)

      assert_has_patch(igniter, @js, """
      - |  hooks: {...colocatedHooks},
      + |  hooks: {...colocatedHooks, ...shadcnHooks},
      """)
    end

    test "keeps CoreComponents' names and imports every other library component", %{
      igniter: igniter
    } do
      assert_has_patch(igniter, @web, """
       |      import MyAppWeb.CoreComponents
      + |      # shadcn_liveview components. CoreComponents keeps button/input/table/icon
      + |      # with the phx.gen.* API and renders them with shadcn_liveview.
      + |      use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]
      """)
    end

    test "leaves config alone for a Hex dependency", %{igniter: igniter} do
      assert_unchanged(igniter, "config/config.exs")
    end

    test "replaces the daisyUI CoreComponents and Layouts, keeping their API and gettext", %{
      igniter: igniter
    } do
      core = content(igniter, @core)
      layouts = content(igniter, @layouts)

      for module <- [core, layouts] do
        refute module =~ ~r/\b(btn|toast|alert-|navbar|table-zebra|base-\d00|base-content)\b/
      end

      assert core =~ "use Gettext, backend: MyAppWeb.Gettext"
      assert core =~ ~s|Gettext.dgettext(MyAppWeb.Gettext, "errors", msg, opts)|
      assert core =~ ~s|aria-label={gettext("close")}|

      for fun <-
            ~w(flash button input header table list icon show hide translate_error translate_errors) do
        assert core =~ ~r/def #{fun}\(/
      end

      for fun <- ~w(app flash_group theme_toggle) do
        assert layouts =~ ~r/def #{fun}\(/
      end

      assert layouts =~ ~s(data-phx-theme="dark")
      assert layouts =~ ~s|title={gettext("We can't find the internet")}|
    end

    test "maps the home page's daisyUI classes to shadcn tokens", %{igniter: igniter} do
      home = content(igniter, @home)
      refute home =~ ~r/\b(badge|rounded-box|base-\d00|base-content)\b/
      assert home =~ "bg-muted transition group-hover:bg-accent"
      assert home =~ "fill-muted-foreground group-hover:fill-foreground"
    end

    test "adds antialiased to the root layout's body", %{igniter: igniter} do
      assert_has_patch(igniter, @root, """
      - |  <body>
      + |  <body class="antialiased">
      """)
    end

    test "running it again changes nothing", %{igniter: igniter} do
      igniter
      |> apply_igniter!()
      |> install()
      |> assert_unchanged()
    end
  end

  test "path dependencies get the build lib directory in both NODE_PATHs" do
    igniter =
      project(%{}, dep: ~s({:shadcn_liveview, path: "../shadcn-liveview"}))
      |> install()

    config = content(igniter, "config/config.exs")

    assert length(
             Regex.scan(
               ~r/"NODE_PATH" => \[\s*Path.expand\("..\/deps", __DIR__\),\s*Mix.Project.build_path\(\),\s*Path.join\(Mix.Project.build_path\(\), "lib"\)\s*\]/,
               config
             )
           ) == 2

    igniter |> apply_igniter!() |> install() |> assert_unchanged()
  end

  test "notices point at the dependency's real location" do
    alias Mix.Tasks.ShadcnLiveview.Install.Docs

    assert Docs.dep_path(%{shadcn_liveview: "/work/shadcn-liveview"}, "/work/apps/my_app") ==
             "../../shadcn-liveview"

    assert Docs.dep_path(%{shadcn_liveview: "/work/my_app/deps/shadcn_liveview"}, "/work/my_app") ==
             "deps/shadcn_liveview"

    assert Docs.dep_path(%{shadcn_liveview: "/home/me/src/shadcn-liveview"}, "/tmp/a/b/c/my_app") ==
             "/home/me/src/shadcn-liveview"

    assert Docs.dep_path(%{phoenix: "/work/my_app/deps/phoenix"}, "/work/my_app") ==
             "deps/shadcn_liveview"

    # The library itself has no :shadcn_liveview dependency, so the notice falls back to deps/.
    project()
    |> install()
    |> assert_has_notice(&(&1 =~ "Agent rules: deps/shadcn_liveview/usage-rules.md"))
  end

  test "--no-core-components keeps CoreComponents and Layouts but still wires the library" do
    project()
    |> install(["--no-core-components"])
    |> assert_unchanged([@core, @layouts])
    |> assert_has_patch(@web, """
    + |      use ShadcnLiveview, except: [button: 1, input: 1, table: 1, icon: 1]
    """)
    |> assert_has_notice(&(&1 =~ "were kept (--no-core-components)"))
  end

  test "--keep-daisyui keeps the plugins, dependency and home page" do
    igniter = project() |> install(["--keep-daisyui"])
    css = content(igniter, @css)

    assert css =~ ~s(@plugin "daisyui/packages/bundle/daisyui")
    assert css =~ "shadcn.tailwind.css"
    refute css =~ "@custom-variant dark"

    assert content(igniter, "mix.exs") =~ "{:daisyui,"

    igniter
    |> assert_unchanged(@home)
    |> assert_has_notice(&(&1 =~ "daisyUI was kept"))
  end

  describe "root layout body" do
    test "prepends antialiased to existing static classes and keeps other attributes" do
      root =
        String.replace(
          @fixtures[@root],
          "<body>",
          ~s(<body data-class="x" class="bg-background min-h-svh" id="app">)
        )

      igniter = project(%{@root => root}) |> install()

      assert content(igniter, @root) =~
               ~s(<body data-class="x" class="antialiased bg-background min-h-svh" id="app">)

      igniter |> apply_igniter!() |> install() |> assert_unchanged()
    end

    test "leaves a body that already has the class alone" do
      root = String.replace(@fixtures[@root], "<body>", ~s(<body class="font-sans antialiased">))
      project(%{@root => root}) |> install() |> assert_unchanged(@root)
    end

    test "warns instead of rewriting a dynamic class" do
      root = String.replace(@fixtures[@root], "<body>", ~s(<body class={@body_class}>))

      project(%{@root => root})
      |> install()
      |> assert_unchanged(@root)
      |> assert_has_warning(&(&1 =~ "add the `antialiased` class to <body> by hand"))
    end
  end

  describe ".credo.exs" do
    @credo_checks "{ShadcnLiveview.Credo.ComposerFormClears, []}, {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}"

    test "without one, adds Credo and a config that keeps the default checks" do
      igniter = project() |> install()

      assert content(igniter, "mix.exs") =~
               ~s|{:credo, "~> 1.7", only: [:dev, :test], runtime: false}|

      assert {%{configs: [%{name: "default", checks: checks} = config]}, _} =
               igniter |> content(".credo.exs") |> Code.eval_string()

      assert checks == %{
               extra: [
                 {ShadcnLiveview.Credo.ComposerFormClears, []},
                 {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}
               ]
             }

      assert config |> Map.keys() |> Enum.sort() == [:checks, :name]

      # The checks only compile when Credo is loaded before shadcn_liveview compiles.
      igniter
      |> assert_has_task("deps.compile", ["credo", "--include-children"])
      |> assert_has_task("deps.compile", ["shadcn_liveview", "--force"])
    end

    test "an app that already has Credo keeps its dependency and needs no recompile" do
      igniter =
        project(%{}, dep: ~s({:shadcn_liveview, "~> 0.1"},\n      {:credo, "~> 1.6", only: :dev}))
        |> install()

      mix_exs = content(igniter, "mix.exs")
      assert mix_exs =~ ~s|{:credo, "~> 1.6", only: :dev}|
      refute mix_exs =~ ~s|{:credo, "~> 1.7"|
      assert {"deps.compile", ["shadcn_liveview", "--force"]} not in igniter.tasks
    end

    test "--no-credo leaves Credo alone" do
      igniter = project() |> install(["--no-credo"])
      refute content(igniter, "mix.exs") =~ ":credo"
      refute_creates(igniter, ".credo.exs")
      assert Enum.all?(igniter.tasks, &(elem(&1, 0) != "deps.compile"))
    end

    test "mix credo gen.config style: appends to checks.enabled once" do
      credo = """
      %{
        configs: [
          %{
            name: "default",
            strict: true,
            checks: %{
              enabled: [
                {Credo.Check.Readability.ModuleDoc, []}
              ],
              disabled: []
            }
          }
        ]
      }
      """

      igniter = project(%{".credo.exs" => credo}) |> install()
      config = content(igniter, ".credo.exs")

      assert config =~
               ~r/enabled: \[\s*\{Credo.Check.Readability.ModuleDoc, \[\]\},\s*\{ShadcnLiveview.Credo.ComposerFormClears, \[\]\},\s*\{ShadcnLiveview.Credo.ChatUsesMessageScroller, \[\]\}\s*\]/

      refute config =~ "extra:"
      assert {%{configs: [%{checks: %{enabled: [_, _, _]}}]}, _} = Code.eval_string(config)

      igniter |> apply_igniter!() |> install() |> assert_unchanged()
    end

    test "adds checks.extra next to other check settings, or a checks map when missing" do
      for {credo, expected} <- [
            {~s|%{configs: [%{name: "default", checks: %{disabled: [{Credo.Check.Design.TagTODO, []}]}}]}|,
             %{disabled: [{Credo.Check.Design.TagTODO, []}]}},
            {~s|%{configs: [%{name: "default", checks: %{extra: [{MyCheck, []}]}}]}|,
             %{extra: [{MyCheck, []}]}},
            {~s|%{configs: [%{name: "default", files: %{included: ["lib/"]}}]}|, %{}}
          ] do
        igniter = project(%{".credo.exs" => credo}) |> install()
        {%{configs: [config]}, _} = igniter |> content(".credo.exs") |> Code.eval_string()

        assert config.checks ==
                 Map.update(
                   expected,
                   :extra,
                   [
                     {ShadcnLiveview.Credo.ComposerFormClears, []},
                     {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}
                   ],
                   &(&1 ++
                       [
                         {ShadcnLiveview.Credo.ComposerFormClears, []},
                         {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}
                       ])
                 )

        igniter |> apply_igniter!() |> install() |> assert_unchanged()
      end
    end

    test "adds only the missing check and leaves legacy list configs as lists" do
      credo =
        ~s|%{configs: [%{name: "default", checks: [{ShadcnLiveview.Credo.ComposerFormClears, []}]}]}|

      {%{configs: [config]}, _} =
        project(%{".credo.exs" => credo})
        |> install()
        |> content(".credo.exs")
        |> Code.eval_string()

      assert config.checks == [
               {ShadcnLiveview.Credo.ComposerFormClears, []},
               {ShadcnLiveview.Credo.ChatUsesMessageScroller, []}
             ]
    end

    test "warns instead of guessing when the file has no configs list" do
      project(%{".credo.exs" => "import_config \"shared.exs\"\n"})
      |> install()
      |> assert_unchanged(".credo.exs")
      |> assert_has_warning(&(&1 =~ "add `[#{@credo_checks}]` to its checks by hand"))
    end
  end

  describe "usage_rules" do
    @shadcn_entries [
      {:shadcn_liveview, sub_rules: []},
      {:shadcn_liveview, sub_rules: :all, main: false, link: :markdown}
    ]

    defp usage_rules_config(igniter) do
      {:defmodule, _, [_, [do: {:__block__, _, body}]]} =
        igniter |> content("mix.exs") |> Code.string_to_quoted!()

      project =
        Enum.find_value(body, fn
          {:def, _, [{:project, _, _}, [do: config]]} -> config
          _ -> nil
        end)

      case Keyword.fetch(project, :usage_rules) do
        {:ok, quoted} -> quoted |> Code.eval_quoted() |> elem(0)
        :error -> nil
      end
    end

    test "a stock app keeps phx.new's synced Phoenix rules and adds the library's rules and skill" do
      igniter = project() |> install()

      assert content(igniter, "mix.exs") =~ ~s|{:usage_rules, "~> 1.3", only: [:dev]}|

      assert usage_rules_config(igniter) == [
               file: "AGENTS.md",
               usage_rules:
                 ~w(phoenix:elixir phoenix:phoenix phoenix:ecto phoenix:html phoenix:liveview) ++
                   @shadcn_entries,
               skills: [package_skills: [:shadcn_liveview]]
             ]

      igniter
      |> assert_unchanged("AGENTS.md")
      |> assert_has_task("usage_rules.sync", ["--yes"])
      |> assert_has_notice(&(&1 =~ "`mix usage_rules.sync`"))
    end

    test "a synced app is left alone on the next run" do
      igniter = project() |> install() |> apply_igniter!()

      # What `mix usage_rules.sync` writes for the library's main rules.
      agents =
        String.replace(
          @fixtures["AGENTS.md"],
          "<!-- usage-rules-end -->",
          "<!-- shadcn_liveview-start -->\n## shadcn_liveview usage\n<!-- shadcn_liveview-end -->\n<!-- usage-rules-end -->"
        )

      igniter =
        Igniter.update_file(igniter, "AGENTS.md", &Rewrite.Source.update(&1, :content, agents))
        |> apply_igniter!()
        |> install()

      assert_unchanged(igniter)
      assert igniter.tasks == []
    end

    test "an existing config keeps its file and entries and gets the library's appended" do
      config = """
      usage_rules: [
        file: "CLAUDE.md",
        usage_rules: [:ash, {~r/^ash_/, link: :markdown}],
        skills: [location: ".agents/skills", package_skills: [:ash]]
      ]
      """

      igniter =
        project(%{
          "mix.exs" =>
            String.replace(
              @fixtures["mix.exs"],
              "listeners: [Phoenix.CodeReloader]",
              "listeners: [Phoenix.CodeReloader],\n" <> config
            )
        })
        |> install()

      assert [
               file: "CLAUDE.md",
               usage_rules: [:ash, {regex, [link: :markdown]} | shadcn],
               skills: [location: ".agents/skills", package_skills: [:ash, :shadcn_liveview]]
             ] = usage_rules_config(igniter)

      assert regex.source == "^ash_"
      assert shadcn == @shadcn_entries
      assert_has_task(igniter, "usage_rules.sync", ["--yes"])

      igniter |> apply_igniter!() |> install() |> assert_unchanged("mix.exs")
    end

    test "usage_rules: :all already covers the library; only the skill is added" do
      igniter =
        project(%{
          "mix.exs" =>
            String.replace(
              @fixtures["mix.exs"],
              "listeners: [Phoenix.CodeReloader]",
              ~s|listeners: [Phoenix.CodeReloader],\nusage_rules: [file: "AGENTS.md", usage_rules: :all]|
            )
        })
        |> install()

      assert usage_rules_config(igniter) == [
               file: "AGENTS.md",
               usage_rules: :all,
               skills: [package_skills: [:shadcn_liveview]]
             ]
    end

    test "an app with only CLAUDE.md syncs into it" do
      igniter =
        project(%{"AGENTS.md" => nil, "CLAUDE.md" => @fixtures["AGENTS.md"]})
        |> install()

      assert [file: "CLAUDE.md", usage_rules: ["phoenix:elixir" | _], skills: _] =
               usage_rules_config(igniter)
    end

    test "--no-usage-rules leaves usage_rules alone" do
      igniter = project() |> install(["--no-usage-rules"])
      refute content(igniter, "mix.exs") =~ "usage_rules"
      assert Enum.all?(igniter.tasks, &(elem(&1, 0) != "usage_rules.sync"))
      assert_has_notice(igniter, &(&1 =~ "(sync them with `usage_rules`)"))
    end
  end

  test "removes vendored daisyUI from Phoenix 1.8.0/1.8.1 apps" do
    css =
      @fixtures[@css]
      |> String.replace(
        ~s(@plugin "daisyui/packages/bundle/daisyui"),
        ~s(@plugin "../vendor/daisyui")
      )
      |> String.replace(
        ~s(@plugin "daisyui/packages/bundle/daisyui-theme"),
        ~s(@plugin "../vendor/daisyui-theme")
      )
      |> String.replace(
        "/* daisyUI Tailwind Plugin. */",
        """
        /* daisyUI Tailwind Plugin. You can update this file by fetching the latest version with:
           curl -sLO https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js
           Make sure to look at the daisyUI changelog: https://daisyui.com/docs/changelog/ */\
        """
      )

    igniter =
      project(%{
        @css => css,
        "assets/vendor/daisyui.js" => "module.exports = {}\n",
        "assets/vendor/daisyui-theme.js" => "module.exports = {}\n"
      })
      |> install()

    refute content(igniter, @css) =~ ~r/daisy/i
    assert_rms(igniter, ["assets/vendor/daisyui-theme.js", "assets/vendor/daisyui.js"])
  end

  describe "files that differ from the Phoenix defaults are skipped with a warning" do
    test "customized CoreComponents and Layouts" do
      project(%{
        @core =>
          "defmodule MyAppWeb.CoreComponents do\n  use Phoenix.Component\n\n  def icon(assigns), do: ~H\"\"\n  def button(assigns), do: ~H\"\"\n  def input(assigns), do: ~H\"\"\n  def table(assigns), do: ~H\"\"\nend\n",
        @layouts =>
          "defmodule MyAppWeb.Layouts do\n  use MyAppWeb, :html\n  embed_templates \"layouts/*\"\nend\n"
      })
      |> install()
      |> assert_unchanged([@core, @layouts])
      |> assert_has_warning(
        &(&1 =~ "MyAppWeb.CoreComponents (#{@core}) differs from Phoenix's default")
      )
      |> assert_has_warning(
        &(&1 =~ "MyAppWeb.Layouts (#{@layouts}) differs from Phoenix's default")
      )
    end

    test "app.js without the LiveSocket setup and app.css without Tailwind" do
      project(%{
        @js => "import \"phoenix_html\"\n",
        @css => "body { margin: 0; }\n"
      })
      |> install()
      |> assert_unchanged([@js, @css])
      |> assert_has_warning(&(&1 =~ "does not match Phoenix's default LiveSocket setup"))
      |> assert_has_warning(&(&1 =~ ~s(has no `@import "tailwindcss"` line)))
    end

    test "html_helpers without a CoreComponents import" do
      web = String.replace(@fixtures[@web], "      import MyAppWeb.CoreComponents\n", "")

      project(%{@web => web})
      |> install()
      |> assert_unchanged(@web)
      |> assert_has_warning(&(&1 =~ "html_helpers/0 does not import MyAppWeb.CoreComponents"))
    end
  end

  describe "generated CoreComponents" do
    # Compiles the installer's CoreComponents for an app without Gettext and renders the
    # calls phx.gen.html/phx.gen.live templates make.
    setup do
      module = ShadcnInstallerTest.CoreComponents

      if !Code.ensure_loaded?(module) do
        source =
          project(%{"lib/my_app_web/gettext.ex" => nil})
          |> install()
          |> content(@core)
          |> String.replace("MyAppWeb.CoreComponents", inspect(module))

        refute source =~ "use Gettext"
        Code.compile_string(source)
      end

      %{core: module}
    end

    test "input renders labelled shadcn controls and used-input errors", %{core: core} do
      form =
        to_form(
          %{"name" => "", "age" => "3", "bio" => "a <b>", "active" => "true", "role" => "user"},
          as: :user,
          errors: [
            name: {"can't be blank", [validation: :required]},
            age: {"must be at least %{n}", [n: 18]}
          ]
        )

      doc =
        [
          render(core, :input, field: form[:name], label: "Name"),
          render(core, :input, field: form[:age], type: "number", label: "Age"),
          render(core, :input, field: form[:bio], type: "textarea", label: "Bio"),
          render(core, :input, field: form[:active], type: "checkbox", label: "Active"),
          render(core, :input,
            field: form[:role],
            type: "select",
            label: "Role",
            prompt: "Choose",
            options: [Admin: "admin", User: "user"]
          )
        ]
        |> Enum.join()
        |> Floki.parse_fragment!()

      assert text(doc, ~s(label[for="user_name"])) == "Name"
      assert attr(doc, "input#user_name", "data-slot") == "input"
      assert attr(doc, "input#user_name", "aria-invalid") == "true"
      assert attr(doc, "input#user_name", "aria-describedby") == "user_name-error"
      assert text(doc, "#user_name-error") =~ "can't be blank"
      assert text(doc, "#user_age-error") =~ "must be at least 18"
      assert attr(doc, "input#user_age", "value") == "3"
      assert attr(doc, "textarea#user_bio", "data-slot") == "textarea"
      # Floki keeps textarea content as raw text: the value is HTML-escaped once.
      assert text(doc, "textarea#user_bio") == "a &lt;b&gt;"
      assert attr(doc, "input#user_active[type=checkbox]", "checked") != nil
      assert attr(doc, "input[type=hidden][name='user[active]']", "value") == "false"
      assert attr(doc, "select#user_role", "data-slot") == "native-select"
      assert attr(doc, "select#user_role option[selected]", "value") == "user"
      assert text(doc, "select#user_role option[value='']") == "Choose"
    end

    test "inputs called with a name but no id stay labelled", %{core: core} do
      doc =
        [
          render(core, :input, name: "q", value: "", label: "Search"),
          render(core, :input,
            name: "filter[specialty]",
            type: "select",
            label: "Specialty",
            options: ["A"],
            value: nil
          ),
          render(core, :input, name: "note", type: "textarea", label: "Note", value: ""),
          render(core, :input,
            name: "opts[remember]",
            type: "checkbox",
            label: "Remember",
            value: nil
          ),
          render(core, :input,
            name: "tags[]",
            type: "select",
            multiple: true,
            label: "Tags",
            options: ["a"],
            value: []
          )
        ]
        |> Enum.join()
        |> Floki.parse_fragment!()

      for {tag, id, label} <- [
            {"input", "q", "Search"},
            {"select", "filter_specialty", "Specialty"},
            {"textarea", "note", "Note"},
            {"input[type=checkbox]", "opts_remember", "Remember"},
            {"select", "tags", "Tags"}
          ] do
        assert Floki.find(doc, "#{tag}##{id}") != [], "#{tag}##{id} missing"
        assert text(doc, ~s(label[for="#{id}"])) == label
      end

      hidden =
        core
        |> render(:input, name: "token", type: "hidden", value: "t")
        |> Floki.parse_fragment!()

      assert attr(hidden, "input", "id") == nil
    end

    test "input errors render inside the Field without margin hacks", %{core: core} do
      for type <- ~w(text textarea select checkbox) do
        doc =
          core
          |> render(:input,
            name: "x",
            id: "x",
            type: type,
            label: "X",
            value: nil,
            options: ["a"],
            errors: ["is invalid"]
          )
          |> Floki.parse_fragment!()

        assert text(doc, "[data-slot=field] #x-error") == "is invalid", type
        refute attr(doc, "#x-error", "class") =~ "-mt-2"
        refute attr(doc, "[data-slot=field]", "class") =~ "mb-4"
      end
    end

    test "required inputs show form_field's required marker", %{core: core} do
      for type <- ~w(text textarea select checkbox) do
        doc =
          core
          |> render(:input,
            name: "x",
            type: type,
            label: "X",
            value: nil,
            options: ["a"],
            required: true
          )
          |> Floki.parse_fragment!()

        assert text(doc, ~s(label[for="x"] span[aria-hidden=true])) == "*", type
        assert attr(doc, "#x", "required") != nil, type
      end

      optional =
        core |> render(:input, name: "x", label: "X", value: nil) |> Floki.parse_fragment!()

      assert Floki.find(optional, "label span[aria-hidden]") == []
    end

    test "text inputs keep Phoenix's attribute order and the library input classes", %{
      core: core
    } do
      html =
        render(core, :input,
          type: "email",
          name: "member[email]",
          id: "login_form_magic_email",
          value: "a@example.com"
        )

      # phx.gen.auth's generated tests assert this exact prefix.
      assert html =~
               ~s(<input type="email" name="member[email]" id="login_form_magic_email" value="a@example.com")

      library =
        %{__changed__: nil}
        |> Input.input()
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert String.split(attr(Floki.parse_fragment!(html), "input", "class")) ==
               String.split(attr(library, "input", "class"))
    end

    test "button maps phx variants to shadcn and renders links", %{core: core} do
      doc =
        Floki.parse_fragment!(
          render(core, :button, variant: "primary", inner_block: slot("Save")) <>
            render(core, :button, navigate: "/users", inner_block: slot("Back")) <>
            render(core, :button, variant: "destructive", size: "sm", inner_block: slot("Delete"))
        )

      assert attr(doc, "button[data-variant=default]", "data-slot") == "button"
      assert attr(doc, "a[data-variant=outline]", "href") == "/users"
      assert attr(doc, "button[data-variant=destructive]", "data-size") == "sm"
    end

    test "table renders rows, columns and actions with shadcn table slots", %{core: core} do
      doc =
        core
        |> render(:table,
          id: "users",
          rows: [%{id: 1, name: "Ada"}],
          row_id: &"users-#{&1.id}",
          col: [%{__slot__: :col, label: "Name", inner_block: fn _, row -> row.name end}],
          action: [%{__slot__: :action, inner_block: fn _, _row -> "Edit" end}]
        )
        |> Floki.parse_fragment!()

      assert attr(doc, "tbody#users", "data-slot") == "table-body"
      assert text(doc, "tr#users-1 td") =~ "Ada"
      assert text(doc, "tr#users-1") =~ "Edit"
      assert text(doc, "thead th") =~ "Name"
    end

    test "icon renders Heroicons and Lucide names", %{core: core} do
      assert render(core, :icon, name: "hero-x-mark", class: "size-5") =~
               ~s(<span class="hero-x-mark size-5")

      assert render(core, :icon, name: "plus") =~ "<svg"
    end

    test "flash renders a shadcn alert", %{core: core} do
      doc =
        core
        |> render(:flash, kind: :error, flash: %{"error" => "Boom"})
        |> Floki.parse_fragment!()

      assert attr(doc, "#flash-error [data-slot=alert]", "role") == "alert"
      assert text(doc, "#flash-error [data-slot=alert-description]") =~ "Boom"
    end
  end

  defp render(core, function, assigns) do
    assigns = assigns |> Map.new() |> Map.put(:__changed__, nil)
    core |> apply(function, [assigns]) |> rendered_to_string()
  end

  defp slot(text), do: [%{__slot__: :inner_block, inner_block: fn _, _ -> text end}]

  defp attr(doc, selector, name) do
    case Floki.attribute(doc, selector, name) do
      [value | _] -> value
      [] -> nil
    end
  end

  defp text(doc, selector), do: doc |> Floki.find(selector) |> Floki.text() |> String.trim()
end
