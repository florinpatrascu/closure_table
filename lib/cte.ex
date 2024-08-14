defmodule CTE do
  @moduledoc """
  The Closure Table for Elixir strategy, CTE for short,
  is a simple and elegant way of storing and working with
  hierarchies. It involves storing all paths through a tree,
  not just those with a direct parent-child relationship. You
  may want to chose this model, over the [Nested Sets model](https://en.wikipedia.org/wiki/Nested_set_model),
  should you need referential integrity and to assign nodes to multiple trees.

  With CTE you can navigate through hierarchies using a
  simple [API](CTE.Adapter.html#functions), such as:
  finding the ascendants and descendants of a node, inserting
  and deleting nodes, moving entire sub-trees or print them
  as a digraph (.dot) file.

  Options available to most of the functions:

  - `:limit`, to limit the total number of nodes returned, when finding the ancestors or the descendants for nodes
  - `:itself`, accepting a boolean value. When `true`, the node used for finding its neighbors are returned as part of the results. Default: true
  - `:nodes`, accepting a boolean value. When `true`, the results are containing additional information about the nodes. Default: false


  ### Quick example.

  In this example the: `:nodes` attribute, will be a Schema i.e. `Post`, `TreePath`, etc!
  In our initial implementation, the nodes definitions must have at least the
  `:id`, as one of their properties. This caveat will be lifted
  in a later implementation.

  ......

  todo:  Update the docs


  Please check the docs, the tests, and the examples folder, for more details.
  """

  @type config :: Keyword.t()

  @type table :: String.t() | atom
  @type nodes :: map() | table
  @type paths :: [list()] | table
  @type repo :: Ecto.Repo | map()
  @type name :: String.t() | atom

  @type t :: %__MODULE__{
          nodes: nodes | nil,
          paths: paths | nil,
          repo: repo | nil,
          name: name | nil,
          options: map() | nil
        }
  defstruct [:nodes, :paths, :adapter, :repo, :name, :options]

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @opts %CTE{
        nodes: Keyword.get(opts, :nodes, []),
        paths: Keyword.get(opts, :paths, []),
        repo: Keyword.get(opts, :repo, nil),
        options:
          Keyword.get(opts, :options, %{
            node: %{primary_key: :id, type: :integer},
            paths: %{
              ancestor: [type: :integer],
              descendant: [type: :integer]
            }
          })
      }

      def insert(leaf, ancestor, opts \\ [])

      def insert(leaf, ancestor, opts),
        do: CTE.Ecto.insert(leaf, ancestor, opts, @opts)

      def tree(leaf, opts \\ [])
      def tree(leaf, opts), do: CTE.Ecto.tree(leaf, opts, @opts)

      def ancestors(descendant, opts \\ [])

      def ancestors(descendant, opts),
        do: CTE.Ecto.ancestors(descendant, opts, @opts)

      def descendants(ancestor, opts \\ [])

      def descendants(ancestor, opts),
        do: CTE.Ecto.descendants(ancestor, opts, @opts)

      @doc """
      when limit: 1, the default value, then delete only the leafs, else the entire subtree
      """
      def delete(leaf, opts \\ [limit: 1])
      def delete(leaf, opts), do: CTE.Ecto.delete(leaf, opts, @opts)

      def move(leaf, ancestor, opts \\ [])

      def move(leaf, ancestor, opts),
        do: CTE.Ecto.move(leaf, ancestor, opts, @opts)
    end
  end
end
