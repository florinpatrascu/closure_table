defmodule CTE.Adapter.Ecto do
  @moduledoc """
  A CTE Adapter implementation using an existing Ecto Repo for persisting the models.

  The current implementation is depending on Ecto ~> 3.1; using [Ecto.SubQuery](https://hexdocs.pm/ecto/Ecto.SubQuery.html)!

  For this implementation to work you'll have to provide two tables, and the name of the Repo used by your application:

  1. a table name containing the nodes. Having the `id`, as a the primary key
  2. a table name where the tree paths will be stores.
  3. the name of the Ecto.Repo, defined by your app

  In a future version we will provide you with a convenient migration template to help you starting, but for now you must supply these tables.

  For example, given you have the following Schemas for comments:

      defmodule CT.Comment do
        use Ecto.Schema
        import Ecto.Changeset

        @timestamps_opts [type: :utc_datetime]

        schema "comments" do
          field :text, :string
          belongs_to :author, CT.Author

          timestamps()
        end
      end

  and a table used for storing the parent-child relationships

      defmodule CT.TreePath do
        use Ecto.Schema
        import Ecto.Changeset
        alias CT.Comment

        @primary_key false

        schema "tree_paths" do
          belongs_to :parent_comment, Comment, foreign_key: :ancestor
          belongs_to :comment, Comment, foreign_key: :descendant
        end
      end

  we can define the following module:

      defmodule CT.MyCTE do
        use CTE,
        otp_app: :cte,
        adapter: CTE.Adapter.Ecto,
        repo: CT.Repo,
        nodes: CT.Comment,
        paths: CT.TreePath
      end


  We add our CTE Repo to the app's main supervision tree, like this:

      defmodule CT.Application do
        use Application

        def start(_type, _args) do
          children = [
            CT.Repo,
            CT.MyCTE
          ]

          opts = [strategy: :one_for_one, name: CT.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

  restart out app and then using IEx, we can start experimenting. Examples:

      iex» CT.MyCTE.ancestors(9)
      {:ok, [1, 4, 6]}

      iex» CT.MyCTE.tree(6)
      {:ok,
      %{
      nodes: %{
        6 => %CT.Comment{
          __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
          author: #Ecto.Association.NotLoaded<association :author is not loaded>,
          author_id: 2,
          id: 6,
          inserted_at: ~U[2019-07-21 01:10:35Z],
          text: "Everything is easier, than with the Nested Sets.",
          updated_at: ~U[2019-07-21 01:10:35Z]
        },
        8 => %CT.Comment{
          __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
          author: #Ecto.Association.NotLoaded<association :author is not loaded>,
          author_id: 1,
          id: 8,
          inserted_at: ~U[2019-07-21 01:10:35Z],
          text: "I’m sold! And I’ll use its Elixir implementation! <3",
          updated_at: ~U[2019-07-21 01:10:35Z]
        },
        9 => %CT.Comment{
          __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
          author: #Ecto.Association.NotLoaded<association :author is not loaded>,
          author_id: 3,
          id: 9,
          inserted_at: ~U[2019-07-21 01:10:35Z],
          text: "w⦿‿⦿t!",
          updated_at: ~U[2019-07-21 01:10:35Z]
        }
      },
      paths: [[6, 6], [6, 8], [6, 9], '\t\t', '\b\b']
      }}

  Have fun!
  """
  use CTE.Adapter

  import Ecto.Query, warn: false

  @doc false
  def insert(pid, leaf, ancestor, opts) do
    GenServer.call(pid, {:insert, leaf, ancestor, opts})
  end

  @doc false
  def descendants(pid, ancestor, opts) do
    GenServer.call(pid, {:descendants, ancestor, opts})
  end

  @doc false
  def ancestors(pid, descendant, opts) do
    GenServer.call(pid, {:ancestors, descendant, opts})
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

  ######################################
  # server callbacks
  ######################################

  @doc false
  def handle_call({:delete, leaf, true, _opts}, _from, config) do
    %CTE{paths: paths, repo: repo} = config
    query = from p in paths, where: ^leaf == p.descendant
    repo.delete_all(query)
    {:reply, :ok, config}
  end

  @doc false
  def handle_call({:delete, leaf, _subtree, _opts}, _from, config) do
    %CTE{paths: paths, repo: repo} = config

    # DELETE FROM ancestry WHERE descendant IN (SELECT descendant FROM ancestry WHERE ancestor = 100)
    sub = from p in paths, where: p.ancestor == ^leaf

    query =
      from p in paths,
        join: sub in subquery(sub),
        on: p.descendant == sub.descendant

    repo.delete_all(query)

    {:reply, :ok, config}
  end

  @doc false
  def handle_call({:move, leaf, ancestor, _opts}, _from, config) do
    %CTE{paths: paths, repo: repo} = config

    # DELETE FROM ancestry
    #   WHERE descendant IN (SELECT descendant FROM ancestry WHERE ancestor = ^leaf)
    #   AND ancestor IN (SELECT ancestor FROM ancestry WHERE descendant = ^leaf
    #   AND ancestor != descendant);

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

    # INSERT INTO ancestry (ancestor, descendant)
    #   SELECT super_tree.ancestor, sub_tree.descendant FROM ancestry AS super_tree
    #   CROSS JOIN ancestry AS sub_tree WHERE super_tree.descendant = 3
    #   AND sub_tree.ancestor = 6;
    query_insert =
      from super_tree in paths,
        cross_join: sub_tree in ^paths,
        where: super_tree.descendant == ^ancestor,
        where: sub_tree.ancestor == ^leaf,
        select: %{ancestor: super_tree.ancestor, descendant: sub_tree.descendant}

    repo.transaction(fn ->
      repo.delete_all(query_delete)
      inserts = repo.all(query_insert)
      repo.insert_all(paths, inserts)
    end)

    {:reply, :ok, config}
  end

  @doc false
  def handle_call({:descendants, ancestor, opts}, _from, config) do
    results = _descendants(ancestor, opts, config)
    {:reply, {:ok, results}, config}
  end

  @doc false
  def handle_call({:ancestors, descendant, opts}, _from, config) do
    result = _ancestors(descendant, opts, config)
    {:reply, {:ok, result}, config}
  end

  def handle_call({:insert, leaf, ancestor, _opts}, _from, config) do
    result = _insert(leaf, ancestor, config)

    {:reply, result, config}
  end

  @doc false
  def handle_call({:tree, leaf, _opts}, _from, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo} = config

    descendants = _descendants(leaf, [itself: true], config)

    # subtree = Enum.filter(paths, fn [ancestor, _descendant] -> ancestor in descendants end)
    query = from p in paths, where: p.ancestor in ^descendants, select: [p.ancestor, p.descendant]

    subtree = repo.all(query)

    authors =
      subtree
      |> List.flatten()
      |> Enum.uniq()

    query = from n in nodes, where: n.id in ^authors

    some_nodes =
      repo.all(query)
      |> Enum.reduce(%{}, fn node, acc -> Map.put(acc, node.id, node) end)

    {:reply, {:ok, %{paths: subtree, nodes: some_nodes}}, config}
  end

  ######################################
  # private
  ######################################

  @doc false
  defp _insert(leaf, ancestor, config) do
    %CTE{paths: _paths, repo: repo} = config

    descendants =
      _ancestors(ancestor, [itself: true], config)
      |> Enum.map(&[&1, leaf])
      |> Kernel.++([[leaf, leaf]])

    insert_sql = """
    INSERT INTO tree_paths (ancestor, descendant, depth)
    SELECT t.ancestor, #{leaf}, t.depth+1
    FROM tree_paths AS t
    WHERE t.descendant = #{ancestor}
    UNION ALL
    SELECT #{leaf}, #{leaf}, 0;
    """

    with {nr, _r} when nr > 0 <- repo.query(insert_sql) do
      {:ok, descendants}
    else
      e -> {:error, e}
    end
  end

  @doc false
  defp _descendants(ancestor, opts, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo} = config

    # SELECT c. * FROM comments AS c
    # JOIN tree_paths AS t ON c.id = t.descendant
    # WHERE t.ancestor = ^ancestor;
    query =
      from n in nodes,
        join: p in ^paths,
        as: :tree,
        on: n.id == p.descendant,
        where: p.ancestor == ^ancestor

    query
    |> selected(opts, config)
    |> include_itself(opts, config)
    |> depth(opts, config)
    |> top(opts, config)
    |> repo.all()
  end

  @doc false
  defp _ancestors(descendant, opts, config) do
    %CTE{paths: paths, nodes: nodes, repo: repo} = config

    # SELECT c. * FROM comments AS c
    # JOIN tree_paths AS t ON c.id = t.ancestor
    # WHERE t.descendant = ^descendant;
    query =
      from n in nodes,
        join: p in ^paths,
        as: :tree,
        on: n.id == p.ancestor,
        where: p.descendant == ^descendant

    query
    |> selected(opts, config)
    |> include_itself(opts, config)
    |> depth(opts, config)
    |> top(opts, config)
    |> repo.all()
  end

  ######################################
  # Utils
  ######################################
  defp selected(query, opts, _config) do
    if Keyword.get(opts, :nodes, false) do
      from(n in query)
    else
      from n in query, select: n.id
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
      from [tree: t] in query, where: t.depth >= 0 and t.depth <= ^depth
    else
      query
    end
  end
end
