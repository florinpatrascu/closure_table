defmodule CTM.MixProject do
  use Mix.Project

  def project do
    [
      app: :ct_memory,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CTM.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:closure_table, ">= 0.0.0", path: "../../"}]
  end
end
