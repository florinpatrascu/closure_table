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
        paths: [
                 [6, 6, 0],
                 [6, 8, 1],
                 [8, 8, 0],
                 [6, 9, 1],
                 [9, 9, 0]
               ]
      }

  this will output a .dot formatted string that you could use later for generating
  an image: `dot -Tpng <filename>.dot -o <filename>.png`

  """
  @spec print_dot(map, Keyword.t()) :: String.t()
  def print_dot(tree, opts \\ [])

  def print_dot(%{paths: paths, nodes: nodes}, opts)
      when is_list(paths) and is_map(nodes) do
    labels = Keyword.get(opts, :labels, [])
    [[root, _, _] | paths] = paths

    root = Map.get(nodes, root)
    acc = "digraph #{dot_bubble(root, labels)} {"

    Enum.reduce(paths, acc, fn [ancestor, descendant, _depth], acc ->
      parent = Map.get(nodes, ancestor)
      child = Map.get(nodes, descendant)
      acc <> "\n  " <> build_dot(parent, child, labels)
    end) <>
      "\n}\n"
  end

  def print_dot(_, _), do: {:error, :invalid_argument}

  @doc """
  print the tree at the console, using a custom function for selecting the info to be displayed

  The print_tree/3 function receives the tree structure returned by the CTE, the id of an existing node we
  want to start printing the tree with, followed by the options.

  ## Options

    * `:callback` - a function that it is invoked for every node in the tree. Has two parameters:

      * id - the id of the node we render, ao a node specific unique identifier i.e. node name, etc.
      * nodes - the nodes received the tree structure, a map %{node_id => node}...any()

      This function must return a tuple with two elements. First element is the name of the node we render,
      the second one being any optional info you want to add.

    * `:raw` - return a list of tuples if true. Each tuple will contain the depth of
      the text returned from the callback. Useful for custom formatting the output of the print.

  Example, using the default options:

  iex» {:ok, tree} = CTT.tree(1)
  iex» CTE.Utils.print_tree(tree,1, callback: &({&2[&1].author <> ":", &2[&1].comment}))

  Olie: Is Closure Table better than the Nested Sets?
  └── Rolie: It depends. Do you need referential integrity?
   └── Olie: Yeah.

  """
  def print_tree(tree, id, opts \\ [])

  def print_tree(%{paths: paths, nodes: nodes}, id, opts) do
    user_callback = Keyword.get(opts, :callback, fn id, _nodes -> {id, "info..."} end)

    tree =
      paths
      |> Enum.filter(fn [a, d, depth] -> a != d && depth == 1 end)
      |> Enum.group_by(fn [a, _, _] -> a end, fn [_, d, _] -> d end)
      |> Enum.reduce(%{}, fn {parent, children}, acc ->
        descendants = children || []
        Map.put(acc, parent, Enum.uniq(descendants))
      end)

    callback = fn
      node_id when not is_nil(node_id) ->
        {name, info} = user_callback.(node_id, nodes)
        {{name, info}, Map.get(tree, node_id, [])}
    end

    _print_tree([id], callback, opts)
  end

  defp _print_tree(nodes, callback, opts) do
    case print_tree(nodes, _depth = [], _seen = %{}, callback, opts, []) do
      {_seen, [] = out} -> out
      {_, out} -> Enum.reverse(out)
    end
  end

  # credits where credits due:
  # - adapted from a Mix.Utils similar method
  defp print_tree(nodes, depth, seen, callback, opts, out) do
    {nodes, seen} =
      Enum.flat_map_reduce(nodes, seen, fn node, seen ->
        {{name, info}, children} = callback.(node)

        if Map.has_key?(seen, name) do
          {[{name, info, []}], seen}
        else
          {[{name, info, children}], Map.put(seen, name, true)}
        end
      end)

    print_every_node(nodes, depth, seen, callback, opts, out)
  end

  defp print_every_node([], _depth, seen, _callback, _opts, out), do: {seen, out}

  defp print_every_node([{_name, info, children} | nodes], depth, seen, callback, opts, out) do
    raw? = Keyword.get(opts, :raw, false)
    info = if(info, do: info, else: "")

    out =
      if raw? do
        [{length(depth), info} | out]
      else
        # info = if(info, do: " #{info}", else: "")
        # IO.puts("#{depth(depth)}#{prefix(depth, nodes)}#{name}#{info}")
        IO.puts("#{depth(depth)}#{prefix(depth, nodes)}#{info}")
        out
      end

    {seen, out} = print_tree(children, [nodes != [] | depth], seen, callback, opts, out)

    print_every_node(nodes, depth, seen, callback, opts, out)
  end

  defp depth([]), do: ""
  defp depth(depth), do: Enum.reverse(depth) |> tl |> Enum.map(&entry(&1))

  defp entry(true), do: "│  "
  defp entry(false), do: "   "

  defp prefix([], _), do: ""
  defp prefix(_, []), do: "└── "
  defp prefix(_, _), do: "├── "

  @spec build_dot(String.t(), String.t(), list) :: String.t()
  defp build_dot(parent, child, []), do: "#{parent} -> #{child}"

  defp build_dot(parent, child, labels) do
    "#{dot_bubble(parent, labels)} -> #{dot_bubble(child, labels)}"
  end

  defp dot_bubble(node, labels) do
    bubble_text =
      labels
      |> Enum.map(fn
        l when is_function(l) ->
          l.(node) || l

        l ->
          Map.get(node, l, l)
      end)
      |> Enum.join("")

    "\"#{bubble_text}\""
  end

  def tree_to_map(%{paths: paths, nodes: nodes}, id) do
    tree =
      paths
      |> Enum.filter(fn [a, d, depth] -> a != d && depth == 1 end)
      |> Enum.group_by(fn [a, _, _] -> a end, fn [_, d, _] -> d end)
      |> Enum.reduce(%{}, fn {parent, children}, acc ->
        descendants = children || []
        Map.put(acc, parent, Enum.uniq(descendants))
      end)

    _tree_to_map(id, tree, nodes, %{})
  end

  defp _tree_to_map(root, parent_children, nodes, acc) do
    children = Map.get(parent_children, root)

    if children == nil do
      Map.get(nodes, root)
    else
      children = Enum.map(children, &_tree_to_map(&1, parent_children, nodes, acc))
      Map.put(acc, Map.get(nodes, root), children)
    end
  end

end
