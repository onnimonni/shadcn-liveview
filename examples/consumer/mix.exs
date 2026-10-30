defmodule Consumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :consumer,
      version: "0.1.0",
      elixir: "~> 1.18",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: deps(),
      aliases: [
        setup: ["deps.get", "assets.setup", "assets.build"],
        "assets.setup": ["esbuild.install --if-missing"],
        "assets.build": ["esbuild consumer"],
        "assets.deploy": ["esbuild consumer --minify", "phx.digest"]
      ]
    ]
  end

  def application do
    [mod: {Consumer.Application, []}, extra_applications: [:logger, :crypto]]
  end

  defp deps do
    [
      {:shadcn_liveview, path: "../.."},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_live_view, "~> 1.2.12"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto, "~> 3.13"},
      {:phoenix_ecto, "~> 4.6"},
      {:bandit, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:floki, "~> 0.38", only: :test},
      {:lazy_html, "~> 0.1.13", only: :test},
      {:phoenix_test_playwright, "~> 0.18.0", only: :test, runtime: false},
      {:excessibility, "~> 0.20.0", only: :test, runtime: false}
    ]
  end
end
