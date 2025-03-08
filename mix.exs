defmodule Rassifier.MixProject do
  use Mix.Project

  def project do
    [
      app: :rassifier,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
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
      extra_applications: [:logger]
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
      source_ref: "v0.1.0",
      source_url: "https://github.com/elchemista/rassifier"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.36.1"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
