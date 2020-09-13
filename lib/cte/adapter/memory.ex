defmodule CTE.Adapter.Memory do
  @moduledoc """
  Basic implementation of the CTE, using the memory for persisting the models. Adapter provided as a convenient way of using CTE in tests or during the development
  """
  use CTE.Adapter

  @doc false
  def descendants(pid, ancestor, opts) do
    GenServer.call(pid, {:descendants, ancestor, opts})
  end

  @doc false
  def ancestors(pid, descendant, opts) do
    GenServer.call(pid, {:ancestors, descendant, opts})
  end

  @doc false
  def insert(pid, leaf, ancestor, opts) do
    GenServer.call(pid, {:insert, leaf, ancestor, opts})
  end

  @doc """
  Delete a leaf or a subtree.

  To delete a leaf node set the limit option to: 1, and in this particular case
  all the nodes that reference the leaf will be assigned to the leaf's immediate ancestor

  If limit is 0, then the leaf and its descendants will be deleted
  """
  def delete(pid, leaf, opts \\ [limit: 1])

  def delete(pid, leaf, opts) do
    leaf? = Keyword.get(opts, :limit, 1) == 1
    GenServer.call(pid, {:delete, leaf, leaf?, opts})
  end

  @doc false
  def move(pid, leaf, ancestor, opts) do
    GenServer.call(pid, {:move, leaf, ancestor, opts})
  end

  @doc false
  def tree(pid, leaf, opts) do
    GenServer.call(pid, {:tree, leaf, opts})
  end

  @doc false
  def handle_call({:tree, leaf, opts}, _from, config) do
    %CTE{paths: paths, nodes: nodes} = config

    descendants_opts = [itself: true] ++ Keyword.take(opts, [:depth])
    descendants = _descendants(leaf, descendants_opts, config)

    subtree =
      Enum.filter(paths, fn
        [ancestor, descendant, _] ->
          ancestor in descendants && descendant in descendants
      end)

    nodes =
      Enum.reduce(subtree, %{}, fn [ancestor, descendant, _depth], acc ->
        Map.merge(acc, %{
          ancestor => Map.get(nodes, ancestor),
          descendant => Map.get(nodes, descendant)
        })
      end)

    {:reply, {:ok, %{paths: subtree, nodes: nodes}}, config}
  end

  @doc false
  def handle_call({:delete, leaf, true, _opts}, _from, %CTE{paths: paths} = config) do
    leaf_parent =
      with [leaf_parent | _ancestors] <- _ancestors(leaf, [itself: false], config) do
        leaf_parent
      else
        _ -> nil
      end

    paths =
      paths
      |> Enum.reduce([], fn
        [_leaf, ^leaf, _], acc -> acc
        [^leaf, descendant, _depth], acc -> [[leaf_parent, descendant, 1] | acc]
        p, acc -> [p | acc]
      end)
      |> Enum.reverse()

    {:reply, :ok, %{config | paths: paths}}
  end

  @doc false
  def handle_call({:delete, leaf, _subtree, opts}, _from, %{paths: paths} = config) do
    opts = Keyword.put(opts, :itself, true)

    descendants = _descendants(leaf, opts, config) || []

    paths =
      Enum.filter(paths, fn [_ancestor, descendant, _] ->
        descendant not in descendants
      end)

    {:reply, :ok, %{config | paths: paths}}
  end

  @doc false
  def handle_call({:move, leaf, ancestor, _opts}, _from, config) do
    %CTE{paths: paths} = config
    ex_ancestors = _ancestors(leaf, [itself: true], config)

    {descendants_paths, _} = descendants_collector(leaf, [itself: true], config)
    descendants = Enum.map(descendants_paths, fn [_, descendant, _] -> descendant end)

    paths_with_leaf =
      paths
      |> Enum.filter(fn [ancestor, descendant, _] ->
        ancestor in ex_ancestors and descendant in descendants and ancestor != descendant
      end)

    paths_without_leaf = Enum.filter(paths, &(&1 not in paths_with_leaf))

    {new_ancestors_paths, _} =
      ancestors_collector(ancestor, [itself: true], %{config | paths: paths_without_leaf})

    new_paths =
      for [ancestor, _, super_tree_depth] <- [[leaf, leaf, -1] | new_ancestors_paths],
          [_, descendant, subtree_depth] <- descendants_paths,
          into: [] do
        [ancestor, descendant, super_tree_depth + subtree_depth + 1]
      end
      |> Enum.reverse()

    {:reply, :ok, %{config | paths: paths_without_leaf ++ new_paths}}
  end

  @doc false
  def handle_call({:insert, leaf, ancestor, opts}, _from, config) do
    case _insert(leaf, ancestor, opts, config) do
      {:ok, new_paths, config} -> {:reply, {:ok, new_paths}, config}
      err -> {:reply, {:error, err}, config}
    end
  end

  @doc false
  def handle_call({:ancestors, descendant, opts}, _from, config) do
    result =
      _ancestors(descendant, opts, config)
      |> Enum.reverse()

    {:reply, {:ok, result}, config}
  end

  @doc false
  def handle_call({:descendants, ancestor, opts}, _from, config) do
    result =
      _descendants(ancestor, opts, config)
      |> Enum.reverse()

    {:reply, {:ok, result}, config}
  end

  @doc false
  defp _descendants(ancestor, opts, config) do
    descendants_collector(ancestor, opts, config)
    |> depth(opts, config)
    |> selected(opts, config)
  end

  @doc false
  defp descendants_collector(ancestor, opts, config) do
    mapper = fn paths -> Enum.map(paths, fn [_, descendant, _] -> descendant end) end

    fn path, {acc_paths, _mapper, size} = acc, itself? ->
      case path do
        [^ancestor, ^ancestor, _] when not itself? ->
          acc

        [^ancestor, _descendant, _depth] = descendants ->
          {[descendants | acc_paths], mapper, size + 1}

        _ ->
          acc
      end
    end
    |> _find_leaves(opts, config)
  end

  @doc false
  defp _ancestors(descendant, opts, config) do
    ancestors_collector(descendant, opts, config)
    |> depth(opts, config)
    |> selected(opts, config)
  end

  @doc false
  defp ancestors_collector(descendant, opts, config) do
    mapper = fn paths -> Enum.map(paths, fn [ancestor, _, _] -> ancestor end) end

    fn path, {acc_paths, _mapper, size} = acc, itself? ->
      case path do
        [^descendant, ^descendant, _] when not itself? ->
          acc

        [_ancestor, ^descendant, _depth] = ancestors ->
          {[ancestors | acc_paths], mapper, size + 1}

        _ ->
          acc
      end
    end
    |> _find_leaves(opts, config)
  end

  @doc false
  defp _insert(leaf, ancestor, _opts, config) do
    %CTE{nodes: nodes, paths: paths} = config

    case Map.has_key?(nodes, ancestor) do
      true ->
        {leaf_new_ancestors, _} = ancestors_collector(ancestor, [itself: true], config)

        new_paths =
          leaf_new_ancestors
          |> Enum.reduce([[leaf, leaf, 0]], fn [ancestor, _, depth], acc ->
            [[ancestor, leaf, depth + 1] | acc]
          end)

        acc_paths = paths ++ new_paths
        config = %{config | paths: acc_paths}

        {:ok, new_paths, config}

      _ ->
        {:error, :no_ancestor, config}
    end
  end

  @doc false
  defp _find_leaves(fun, opts, %CTE{paths: paths}) do
    itself? = Keyword.get(opts, :itself, false)
    limit = Keyword.get(opts, :limit, 0)

    {leaves_paths, mapper, _size} =
      paths
      |> Enum.reduce_while({[], & &1, 0}, fn path, acc ->
        {_, _, sz} = dsz = fun.(path, acc, itself?)

        if limit == 0 or sz < limit, do: {:cont, dsz}, else: {:halt, dsz}
      end)

    {leaves_paths, mapper}
  end

  @doc false
  defp depth({leaves_paths, mapper}, opts, _config) do
    leaves_paths =
      if depth = Keyword.get(opts, :depth) do
        leaves_paths
        |> Enum.filter(fn [_, _, depth_] -> depth_ <= max(depth, 0) end)
      else
        leaves_paths
      end

    {leaves_paths, mapper}
  end

  @doc false
  defp selected({leaves_paths, mapper}, opts, %CTE{nodes: nodes}) do
    leaves = mapper.(leaves_paths)

    if Keyword.get(opts, :nodes, false) do
      Enum.map(leaves, &Map.get(nodes, &1))
    else
      leaves
    end
  end
end
