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
      3 => %{id: 3, author: "Olie", comment: "Yeah."}
    },
    paths: [[1, 1, 0], [1, 2, 1], [1, 3, 2], [2, 2, 0], [2, 3, 1], [3, 3, 0]]
end

Mix.shell().info([
  :green,
  """
  A CTT module was defined for you. Start is and use it like this:

  iex> CTT.start_link()
  iex> {:ok, tree} = CTT.tree(1)
  iex> CTE.Utils.print_tree(tree, 1)
  iex> CTE.Utils.print_tree(tree,1, callback: &({&2[&1].author <> ":", &2[&1].comment}))
  """
])
