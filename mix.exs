defmodule CTE.MixProject do
  use Mix.Project

  @version "2.0.6"
  @url_docs "https://hexdocs.pm/closure_table"
  @url_github "https://github.com/florinpatrascu/closure_table"

  def project do
    [
      app: :closure_table,
      version: @version,
      elixir: "~> 1.15",
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
        assets: %{"assets" => "assets"},
        formatters: ~w(html),
        source_ref: "v#{@version}",
        source_url: @url_github,
        main: "readme",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, ">= 3.1.0", optional: true, runtime: false},
      {:ecto_sql, ">= 3.1.0", optional: true, runtime: false},
      {:postgrex, ">= 0.17.0", optional: true, runtime: false},

      # dev/test/benching utilities
      {:benchee, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 1.2.0", only: [:dev, :test]},

      # Linting dependencies
      {:credo, "~> 1.7.12", only: [:dev]},
      {:dialyxir, "~> 1.4.5", only: [:dev], runtime: false},

      # mix eye_drops
      {:eye_drops,
       github: "florinpatrascu/eye_drops", ref: "1d8c364", only: [:dev, :test], runtime: false},

      # Documentation dependencies
      # Run me like this: `mix docs`
      {:ex_doc, "~> 0.38.2", only: :dev, runtime: false}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: ~w(lib examples assets mix.exs LICENSE),
      licenses: ["Apache-2.0"],
      maintainers: ["Florin T.PATRASCU", "Greg Rychlewski"],
      links: %{
        "Docs" => @url_docs,
        "Github" => @url_github
      }
    }
  end
end
