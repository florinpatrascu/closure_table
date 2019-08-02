defmodule CTE.Utils do
  @moduledoc """
  Basic utilities for helping developing functionality about the `CTE` data structures
  """

  @doc """
  render a path hierarchy as a .dot string that you could use for drawing your results, using graphviz.  w⦿‿⦿t!

  Upon receiving something like this:

      %{
        nodes: %{
          6 => %{
            author: "Rolie",
            comment: "Everything is easier, than with the Nested Sets.",
            id: 6
          },
          8 => %{
            author: "Olie",
            comment: "I’m sold! And I’ll use its Elixir implementation! <3",
            id: 8
          },
          9 => %{author: "Polie", comment: "w⦿‿⦿t!", id: 9}
        },
        paths: [[6, 6], [6, 8], [6, 9], '\t\t', '\b\b']
      }

  this will output a .dot formatted string that you could use later for generating
  an image: `dot -Tpng <filename>.dot -o <filename>.png`

  """
  @spec print_dot(map, Keyword.t()) :: String.t()
  def print_dot(tree, opts \\ [])

  def print_dot(%{paths: paths, nodes: nodes}, opts)
      when is_list(paths) and is_map(nodes) do
    labels = Keyword.get(opts, :labels, [])
    [[root, _] | paths] = paths

    root = Map.get(nodes, root)
    acc = "digraph #{dot_bubble(root, labels)} {"

    Enum.reduce(paths, acc, fn [ancestor, descendant], acc ->
      parent = Map.get(nodes, ancestor)
      child = Map.get(nodes, descendant)
      acc <> "\n  " <> build_dot(parent, child, labels)
    end) <>
      "\n}\n"
  end

  def print_dot(_, _), do: {:error, :invalid_argument}

  @spec build_dot(String.t(), String.t(), list) :: String.t()
  defp build_dot(parent, child, []), do: "#{parent} -> #{child}"

  defp build_dot(parent, child, labels) do
    "#{dot_bubble(parent, labels)} -> #{dot_bubble(child, labels)}"
  end

  defp dot_bubble(node, labels) do
    bubble_text =
      labels
      |> Enum.map(&Map.get(node, &1, &1))
      |> Enum.join("")

    "\"#{bubble_text}\""
  end
end
