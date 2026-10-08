defmodule ShadcnLiveview.MixProject do
  use Mix.Project

  def project do
    [
      app: :shadcn_liveview,
      version: "0.1.0",
      elixir: "~> 1.18",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: deps(),
      aliases: [
        "assets.build": ["compile", "esbuild shadcn_liveview", "cmd bash tools/build-assets.sh"],
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

  defp deps do
    [
      {:phoenix, "~> 1.8.0"},
      {:phoenix_live_view, "~> 1.2.12"},
      {:phoenix_html, "~> 4.3"},
      {:bandit, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:esbuild, "~> 0.10"},
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:floki, "~> 0.38", only: :test}
    ]
  end
end
