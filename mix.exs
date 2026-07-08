defmodule LanternUI.MixProject do
  use Mix.Project

  @version "0.3.2"
  @source_url "https://github.com/go9/lantern-ui"

  def project do
    [
      app: :lantern_ui,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "LanternUI",
      description:
        "Native Phoenix LiveView UI components — server-rendered SVG charts and more, " <>
          "themeable via CSS variables (Fluxon-compatible). No React, no JS chart libraries.",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
