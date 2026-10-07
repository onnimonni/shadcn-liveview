defmodule ShadcnLiveview.MixProject do
  use Mix.Project
  def project do
    [app: :shadcn_liveview, version: "0.1.0", elixir: "~> 1.18", compilers: [:phoenix_live_view] ++ Mix.compilers(), deps: deps(), aliases: ["assets.build": ["compile", "cmd npm run build:assets"]]]
  end
  def application, do: [extra_applications: [:logger, :crypto], mod: {ShadcnLiveview.Application, []}]
  defp deps do
    [{:phoenix, "~> 1.8.0"}, {:phoenix_live_view, "~> 1.2.12"}, {:phoenix_html, "~> 4.3"}, {:bandit, "~> 1.8"}, {:jason, "~> 1.4"}, {:floki, "~> 0.38", only: :test}]
  end
end
