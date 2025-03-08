defmodule Rassifier.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :rassifier,
      version: @version,
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Rassifier",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  defp description do
    "Rassifier is an Elixir library that provides low-resource text classification powered by a Rust implementation"
  end

  defp package do
    [
      maintainers: ["elchemista"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/elchemista/rassifier"},
      files: ~w(mix.exs README.md lib native test LICENSE checksum-*.exs .formatter.exs)
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v0.1.1",
      source_url: "https://github.com/elchemista/rassifier"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, ">= 0.0.0", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.35", only: :dev}
    ]
  end
end
