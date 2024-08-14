defmodule CTE.Ecto do
  @moduledoc """
  Most of the functions provided will accept the following options:

  - `:limit`, to limit the total number of nodes returned, when finding the ancestors or the descendants for nodes
  - `:itself`, accepting a boolean value. When `true`, the node used for finding its neighbors are returned as part of the results. Default: true
  - `:nodes`, accepting a boolean value. When `true`, the results are containing additional information about the nodes. Default: false
  """
  import Ecto.Query, warn: false

  @doc """
  Delete a leaf or a subtree.

  To delete a leaf node set the limit option to: 1, and in this particular case
  all the nodes that reference the leaf will be assigned to the leaf's immediate ancestor

  If limit is 0, then the leaf and its descendants will be deleted
  """
  def delete(leaf, opts, config) do
    leaf? = Keyword.get(opts, :limit, 1) == 1
    _delete(leaf, leaf?, opts, config)
  end

  @doc """
  Move a subtree from one location to another.

  First, the subtree and its descendants are disconnected from its ancestors. And second, the subtree is inserted under the new parent (ancestor) and the subtree, including its descendants, is declared as descendants of all the new ancestors.
  """
  def move(leaf, ancestor, opts, config) do
    _move(leaf, ancestor, opts, config)
  end

  @doc """
  Retrieve the descendants of a node
  """
  def descendants(ancestor, opts, config) do
    {:ok, _descendants(ancestor, opts, config)}
  end

  @doc """
  Retrieve the ancestors of a node
  """
  def ancestors(descendant, opts, config) do
    {:ok, _ancestors(descendant, opts, config)}
  end

  @doc """
  Insert a node under an existing ancestor
  """

  def insert(leaf, ancestor, _opts, config) do
    _insert(leaf, ancestor, config)
  end

  @doc """
  Calculate and return a "tree" structure containing the paths and the nodes under the given leaf/node
  """

  def tree(leaf, opts, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo, options: options} = config
    %{primary_key: pk} = options.node

    descendants_opts = [itself: true] ++ Keyword.take(opts, [:depth])
    descendants = _descendants(leaf, descendants_opts, config)

    query =
      from p in paths,
        where: p.ancestor in ^descendants,
        select: [p.ancestor, p.descendant, p.depth]

    subtree =
      query
      |> prune(descendants, opts, config)
      |> repo.all()

    unique_descendants =
      subtree
      |> Enum.map(fn [_ancestor, descendant, _depth] -> descendant end)
      |> Enum.uniq()

    query = from n in nodes, where: field(n, ^pk) in ^unique_descendants

    some_nodes =
      repo.all(query)
      |> Enum.reduce(%{}, fn node, acc -> Map.put(acc, Map.get(node, pk), node) end)

    {:ok, %{paths: subtree, nodes: some_nodes}}
  end

  ######################################
  # private
  ######################################

  @doc false
  defp _insert(leaf, ancestor, config) do
    %CTE{paths: paths, repo: repo, options: options} = config
    %{descendant: [type: descendant_type]} = options.paths

    descendants =
      from p in paths,
        where: p.descendant == ^ancestor,
        select: %{
          ancestor: p.ancestor,
          descendant: type(^leaf, ^descendant_type),
          depth: p.depth + 1
        }

    new_records = repo.all(descendants) ++ [%{ancestor: leaf, descendant: leaf, depth: 0}]

    descendants = Enum.map(new_records, fn r -> [r.ancestor, r.descendant] end)

    case repo.insert_all(paths, new_records, on_conflict: :nothing) do
      {_nr, _r} ->
        {:ok, descendants}

      e ->
        {:error, e}
    end
  end

  @doc false
  defp _descendants(ancestor, opts, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo, options: options} = config
    %{primary_key: pk} = options.node
    # %{descendant: [type: descendant_type]} = options.paths

    query =
      from n in nodes,
        join: p in ^paths,
        as: :tree,
        on: field(n, ^pk) == p.descendant,
        where: p.ancestor == ^ancestor,
        order_by: [asc: p.depth]

    query
    |> selected(opts, config)
    |> include_itself(opts, config)
    |> depth(opts, config)
    |> top(opts, config)
    |> repo.all()
  end

  @doc false
  defp _ancestors(descendant, opts, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo, options: options} = config
    %{primary_key: pk} = options.node

    query =
      from n in nodes,
        join: p in ^paths,
        as: :tree,
        on: field(n, ^pk) == p.ancestor,
        where: p.descendant == ^descendant,
        order_by: [desc: p.depth]

    query
    |> selected(opts, config)
    |> include_itself(opts, config)
    |> depth(opts, config)
    |> top(opts, config)
    |> repo.all()
  end

  defp _move(leaf, ancestor, _opts, config) do
    %CTE{paths: paths, repo: repo} = config

    q_ancestors =
      from p in paths,
        where: p.descendant == ^leaf,
        where: p.ancestor != p.descendant

    q_descendants =
      from p in paths,
        where: p.ancestor == ^leaf

    query_delete =
      from p in paths,
        join: d in subquery(q_descendants),
        on: p.descendant == d.descendant,
        join: a in subquery(q_ancestors),
        on: p.ancestor == a.ancestor

    query_insert =
      from super_tree in paths,
        cross_join: sub_tree in ^paths,
        where: super_tree.descendant == ^ancestor,
        where: sub_tree.ancestor == ^leaf,
        select: %{
          ancestor: super_tree.ancestor,
          descendant: sub_tree.descendant,
          depth: super_tree.depth + sub_tree.depth + 1
        }

    repo.transaction(fn ->
      deleted = repo.delete_all(query_delete)
      inserts = repo.all(query_insert)
      inserted = repo.insert_all(paths, inserts)

      %{deleted: deleted, inserted: inserted}
    end)
  end

  ######################################
  # Utils
  ######################################
  defp selected(query, opts, config) do
    %CTE{options: options} = config
    %{primary_key: pk} = options.node

    if Keyword.get(opts, :nodes, false) do
      from(n in query)
    else
      from n in query, select: field(n, ^pk)
    end
  end

  defp include_itself(query, opts, _config) do
    if Keyword.get(opts, :itself, false) do
      query
    else
      from [tree: t] in query, where: t.ancestor != t.descendant
    end
  end

  defp top(query, opts, _config) do
    if limit = Keyword.get(opts, :limit) do
      from q in query, limit: ^limit
    else
      query
    end
  end

  defp depth(query, opts, _config) do
    if depth = Keyword.get(opts, :depth) do
      from [tree: t] in query, where: t.depth <= ^max(depth, 0)
    else
      query
    end
  end

  defp prune(query, descendants, opts, _config) do
    if depth = Keyword.get(opts, :depth) do
      from t in query, where: t.descendant in ^descendants and t.depth <= ^max(depth, 0)
    else
      query
    end
  end

  @doc false
  defp _delete(leaf, true, _opts, config) do
    %CTE{paths: paths, repo: repo} = config

    descendants = _descendants(leaf, [itself: false], config) || []

    query_delete_leaf =
      from p in paths,
        where: ^leaf in [p.ancestor, p.descendant] and p.depth >= 0,
        select: %{ancestor: p.ancestor, descendant: p.descendant, depth: p.depth}

    query_move_leafs_kids_up =
      from p in paths,
        where: p.descendant in ^descendants and p.depth >= 1,
        update: [
          set: [
            depth: p.depth - 1
          ]
        ]

    repo.transaction(fn ->
      deleted = repo.delete_all(query_delete_leaf)
      updated = repo.update_all(query_move_leafs_kids_up, [])

      %{deleted: deleted, updated: updated}
    end)
  end

  @doc false
  defp _delete(leaf, _subtree, _opts, %CTE{paths: paths, repo: repo}) do
    sub = from p in paths, where: p.ancestor == ^leaf

    query =
      from p in paths,
        join: sub in subquery(sub),
        on: p.descendant == sub.descendant

    case repo.delete_all(query) do
      {_deleted, _} = d -> {:ok, %{deleted: d, updated: {0, nil}}}
      e -> e
    end
  end
end
