defmodule CTE.MixProject do
  use Mix.Project

  @version "0.1.3"
  @url_docs "https://hexdocs.pm/closure_table"
  @url_github "https://github.com/florinpatrascu/closure_table"

  def project do
    [
      app: :closure_table,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description:
        "Closure Table for Elixir - a simple solution for storing and manipulating complex hierarchies.",
      build_embedded: Mix.env() == :prod,
      name: "Closure Table",
      start_permanent: Mix.env() == :prod,
      docs: [
        name: "Closure Table",
        logo: "assets/logo.png",
        assets: "assets",
        source_ref: "v#{@version}",
        source_url: @url_github,
        main: "README",
        extras: [
          "README.md",
          "CHANGELOG.md"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CTE.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # optional Ecto support
      {:ecto, "~> 3.1", optional: true, runtime: false},
      {:ecto_sql, "~> 3.1", optional: true, runtime: false},
      {:postgrex, ">= 0.0.0", optional: true, runtime: false},

      # dev/test/benching utilities
      {:benchee, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.9", only: [:dev, :test]},

      # Linting dependencies
      {:credo, "~> 1.1", only: [:dev]},
      {:dialyxir, "1.0.0-rc.6", only: [:dev], runtime: false},

      # mix eye_drops
      {:eye_drops, github: "florinpatrascu/eye_drops", only: [:dev, :test], runtime: false},

      # Documentation dependencies
      # Run me like this: `mix docs`
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [
        "lib",
        "examples",
        "assets",
        "mix.exs",
        "LICENSE"
      ],
      licenses: ["Apache 2.0"],
      maintainers: ["Florin T.PATRASCU"],
      links: %{
        "Docs" => @url_docs,
        "Github" => @url_github
      }
    }
  end
end
