try do
  Code.eval_file(".iex.exs", "~")
rescue
  Code.LoadError -> :rescued
end

defmodule CTT do
  use CTE,
    otp_app: :cte,
    adapter: CTE.Adapter.Memory,
    nodes: %{
      1 => %{id: 1, author: "Olie", comment: "Is Closure Table better than the Nested Sets?"},
      2 => %{id: 2, author: "Rolie", comment: "It depends. Do you need referential integrity?"},
      3 => %{id: 3, author: "Polie", comment: "Yeah."}
    },
    paths: [[1, 1], [1, 2], [1, 3], [2, 2], [2, 3], [3, 3]]
end

Mix.shell().info([
  :green,
  """
  CTT module defined, for test. And you start it like this:

  CTT.start_link()
  """
])
