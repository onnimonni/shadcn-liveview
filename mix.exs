defmodule ShadcnLiveview.MixProject do
  use Mix.Project

  def project do
    [
      app: :shadcn_liveview,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "Native shadcn/ui components and portable assets for Phoenix LiveView",
      package: package(),
      source_url: "https://github.com/onnimonni/shadcn-liveview",
      docs: docs(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      elixirc_paths: if(Mix.env() == :test, do: ["lib", "test/support"], else: ["lib"]),
      deps: deps(),
      aliases: [
        "assets.build": ["compile", "esbuild shadcn_liveview", "cmd bash tools/build-assets.sh"],
        "assets.package": ["compile", "cmd bash tools/build-assets.sh --package"],
        quality: [
          "format --check-formatted",
          "compile --force --warnings-as-errors",
          "credo --strict"
        ]
      ]
    ]
  end

  def application,
    do: [extra_applications: [:logger, :crypto], mod: {ShadcnLiveview.Application, []}]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/onnimonni/shadcn-liveview"},
      files: [
        "mix.exs",
        "README.md",
        "LICENSE",
        "NOTICE",
        "lib/shadcn_liveview.ex",
        "lib/shadcn_liveview/{application,helpers,form,data_table}.ex",
        "lib/shadcn_liveview/data_table/*.ex",
        "lib/shadcn_liveview/credo/*.ex",
        "lib/shadcn_liveview/components/*.ex",
        "lib/mix/tasks/shadcn_liveview.install.ex",
        "priv/templates/shadcn_liveview.install",
        "priv/static/shadcn.css",
        "priv/static/shadcn.tailwind.css",
        "priv/static/shadcn-hooks.js",
        "priv/shadcn-to-liveview.mjs",
        "usage-rules.md",
        "usage-rules"
      ]
    ]
  end

  # ExDoc 0.40+ also emits llms.txt and Markdown pages for agents.
  defp docs do
    [
      main: "ShadcnLiveview",
      extras: ["README.md", "usage-rules.md" | Path.wildcard("usage-rules/*.md")],
      groups_for_extras: [
        "Agent usage rules": ["usage-rules.md" | Path.wildcard("usage-rules/*.md")]
      ],
      groups_for_modules: [Components: ~r/^ShadcnLiveview\.Components\./]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.0"},
      {:phoenix_live_view, "~> 1.2.12"},
      {:phoenix_html, "~> 4.3"},
      {:bandit, "~> 1.8", only: [:dev, :test]},
      {:jason, "~> 1.4"},
      {:igniter, "~> 0.8.4", optional: true},
      {:esbuild, "~> 0.10", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      # Optional: apps that use Credo get the ShadcnLiveview.Credo.* checks compiled in.
      {:credo, "~> 1.7", optional: true, runtime: false},
      {:floki, "~> 0.38", only: :test},
      {:phoenix_test_playwright, "~> 0.18.0", only: :test, runtime: false},
      {:excessibility, "~> 0.20.0", only: :test, runtime: false}
    ]
  end
end
