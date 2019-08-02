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

  @doc false
  def delete(pid, leaf, opts) do
    leaf? = Keyword.get(opts, :limit, 0) == 1
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
  def handle_call({:tree, leaf, _opts}, _from, config) do
    %CTE{paths: paths, nodes: nodes} = config

    descendants = _descendants(leaf, [itself: true], config)

    subtree = Enum.filter(paths, fn [ancestor, _descendant] -> ancestor in descendants end)

    nodes =
      subtree
      |> Enum.reduce(%{}, fn [ancestor, descendant], acc ->
        Map.merge(acc, %{
          ancestor => Map.get(nodes, ancestor),
          descendant => Map.get(nodes, descendant)
        })
      end)

    {:reply, {:ok, %{paths: subtree, nodes: nodes}}, config}
  end

  @doc false
  def handle_call({:delete, leaf, true, _opts}, _from, config) do
    %CTE{paths: paths} = config
    paths = Enum.filter(paths, fn [_ancestor, descendant] -> descendant != leaf end)
    {:reply, :ok, %{config | paths: paths}}
  end

  @doc false
  def handle_call({:delete, leaf, _subtree, opts}, _from, config) do
    opts = Keyword.put(opts, :itself, true)

    descendants = _descendants(leaf, opts, config)

    paths = Enum.filter(descendants, &(&1 != leaf))
    {:reply, :ok, %{config | paths: paths}}
  end

  @doc false
  def handle_call({:move, leaf, ancestor, _opts}, _from, config) do
    %CTE{paths: paths} = config
    ex_ancestors = _ancestors(leaf, [itself: true], config)
    descendants = _descendants(leaf, [itself: true], config)

    paths_with_leaf =
      paths
      |> Enum.filter(fn [ancestor, descendant] ->
        ancestor in ex_ancestors and descendant in descendants and ancestor != descendant
      end)

    paths_without_leaf = Enum.filter(paths, &(&1 not in paths_with_leaf))

    new_ancestors =
      _ancestors(ancestor, [itself: true], %{config | paths: paths_without_leaf})
      |> Enum.reverse()

    new_paths =
      for ancestor <- new_ancestors ++ [leaf], descendant <- descendants, into: [] do
        [ancestor, descendant]
      end

    {:reply, :ok, %{config | paths: paths_without_leaf ++ new_paths}}
  end

  @doc false
  def handle_call({:insert, leaf, ancestor, opts}, _from, config) do
    with {:ok, new_paths, config} <- _insert(leaf, ancestor, opts, config) do
      {:reply, {:ok, new_paths}, config}
    else
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
    fn path, {descendants, size} = acc, itself? ->
      case path do
        [^ancestor, ^ancestor] when not itself? ->
          acc

        [^ancestor, descendant] ->
          {[descendant | descendants], size + 1}

        _ ->
          acc
      end
    end
    |> _find_leaves(opts, config)
  end

  @doc false
  defp _ancestors(descendant, opts, config) do
    fn path, {ancestors, size} = acc, itself? ->
      case path do
        [^descendant, ^descendant] when not itself? ->
          acc

        [ancestor, ^descendant] ->
          {[ancestor | ancestors], size + 1}

        _ ->
          acc
      end
    end
    |> _find_leaves(opts, config)
  end

  @doc false
  defp _insert(leaf, ancestor, opts, config) do
    %CTE{nodes: nodes, paths: paths} = config

    with true <- Map.has_key?(nodes, ancestor) do
      leaf_new_ancestors =
        _ancestors(ancestor, opts, config)
        |> Enum.map(&[&1, leaf])

      new_paths =
        [[leaf, leaf], [ancestor, leaf] | leaf_new_ancestors]
        |> Enum.reverse()

      config = %{config | paths: new_paths ++ paths}
      {:ok, new_paths, config}
    else
      _ -> {:error, :no_ancestor, config}
    end
  end

  @doc false
  defp _find_leaves(fun, opts, %CTE{nodes: nodes, paths: paths}) do
    nodes? = Keyword.get(opts, :nodes, false)
    itself? = Keyword.get(opts, :itself, false)
    limit = Keyword.get(opts, :limit, 0)

    {leaves, _size} =
      paths
      |> Enum.reduce_while({[], 0}, fn path, acc ->
        {_, sz} = dsz = fun.(path, acc, itself?)

        if limit == 0 or sz < limit, do: {:cont, dsz}, else: {:halt, dsz}
      end)

    if nodes?, do: Enum.map(leaves, &Map.get(nodes, &1)), else: leaves
  end
end
