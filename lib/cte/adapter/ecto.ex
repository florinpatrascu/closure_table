if match?({:module, Ecto}, Code.ensure_compiled(Ecto)) do
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
            field :depth, :integer, default: 0
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
        paths: [
                [6, 6, 0],
                [6, 8, 1],
                [8, 8, 0],
                [6, 9, 1],
                [9, 9, 0]
              ]
        }}

    Have fun!


    Most of the functions implementing the `CTE.Adapter` behavior, will accept the following options:

    - `:limit`, to limit the total number of nodes returned, when finding the ancestors or the descendants for nodes
    - `:itself`, accepting a boolean value. When `true`, the node used for finding its neighbors are returned as part of the results. Default: true
    - `:nodes`, accepting a boolean value. When `true`, the results are containing additional information about the nodes. Default: false
    """
    use CTE.Adapter

    import Ecto.Query, warn: false

    @doc """
    Insert a node under an existing ancestor
    """
    def insert(pid, leaf, ancestor, opts) do
      GenServer.call(pid, {:insert, leaf, ancestor, opts})
    end

    @doc """
    Retrieve the descendants of a node
    """
    def descendants(pid, ancestor, opts) do
      GenServer.call(pid, {:descendants, ancestor, opts})
    end

    @doc """
    Retrieve the ancestors of a node
    """
    def ancestors(pid, descendant, opts) do
      GenServer.call(pid, {:ancestors, descendant, opts})
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

    @doc """
    Move a subtree from one location to another.

    First, the subtree and its descendants are disconnected from its ancestors. And second, the subtree is inserted under the new parent (ancestor) and the subtree, including its descendants, is declared as descendants of all the new ancestors.
    """
    def move(pid, leaf, ancestor, opts) do
      GenServer.call(pid, {:move, leaf, ancestor, opts})
    end

    @doc """
    Calculate and return a "tree" structure containing the paths and the nodes under the given leaf/node
    """
    def tree(pid, leaf, opts) do
      GenServer.call(pid, {:tree, leaf, opts})
    end

    ######################################
    # server callbacks
    ######################################

    @doc false
    def handle_call({:delete, leaf, true, _opts}, _from, config) do
      %CTE{paths: paths, repo: repo} = config

      descendants = _descendants(leaf, [itself: false], config) || []

      query_delete_leaf =
        from p in paths,
          where: ^leaf in [p.ancestor, p.descendant] and p.depth >= 0,
          select: %{ancestor: p.ancestor, descendant: p.descendant, depth: p.depth}

      # repo.all(query_delete_leaf)
      # |> IO.inspect(label: "DELETE: ")

      query_move_leafs_kids_up =
        from p in paths,
          where: p.descendant in ^descendants and p.depth >= 1,
          update: [
            set: [
              depth: p.depth - 1
            ]
          ]

      repo.transaction(fn ->
        repo.delete_all(query_delete_leaf)
        repo.update_all(query_move_leafs_kids_up, [])
      end)

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
    def handle_call({:move, leaf, ancestor, opts}, _from, config) do
      results = _move(leaf, ancestor, opts, config)
      {:reply, results, config}
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
    def handle_call({:tree, leaf, opts}, _from, config) do
      %CTE{paths: paths, nodes: nodes, repo: repo} = config

      descendants_opts = [itself: true] ++ Keyword.take(opts, [:depth])
      descendants = _descendants(leaf, descendants_opts, config)

      # subtree = Enum.filter(paths, fn [ancestor, _descendant] -> ancestor in descendants end)
      query =
        from p in paths,
          where: p.ancestor in ^descendants,
          select: [p.ancestor, p.descendant, p.depth]

      subtree =
        query
        |> prune(descendants, opts, config)
        |> repo.all()

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
      %CTE{paths: paths, repo: repo} = config

      # SELECT t.ancestor, #{leaf}, t.depth + 1
      # FROM tree_paths AS t
      # WHERE t.descendant = #{ancestor}
      descendants =
        from p in paths,
          where: p.descendant == ^ancestor,
          select: %{ancestor: p.ancestor, descendant: type(^leaf, :integer), depth: p.depth + 1}

      new_records = repo.all(descendants) ++ [%{ancestor: leaf, descendant: leaf, depth: 0}]
      descendants = Enum.map(new_records, fn r -> [r.ancestor, r.descendant] end)

      case repo.insert_all(paths, new_records, on_conflict: :nothing) do
        {_nr, _r} ->
          #  l when l == nr <- length(new_records) do
          {:ok, descendants}

        e ->
          {:error, e}
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
      %CTE{paths: paths, nodes: nodes, repo: repo} = config

      # SELECT c. * FROM comments AS c
      # JOIN tree_paths AS t ON c.id = t.ancestor
      # WHERE t.descendant = ^descendant;
      query =
        from n in nodes,
          join: p in ^paths,
          as: :tree,
          on: n.id == p.ancestor,
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
          select: %{
            ancestor: super_tree.ancestor,
            descendant: sub_tree.descendant,
            depth: super_tree.depth + sub_tree.depth + 1
          }

      repo.transaction(fn ->
        repo.delete_all(query_delete)
        inserts = repo.all(query_insert)
        repo.insert_all(paths, inserts)
      end)
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
        from [tree: t] in query, where: t.depth <= ^max(depth, 0)
      else
        query
      end
    end

    defp prune(query, descendants, opts, _config) do
      if Keyword.get(opts, :depth) do
        from t in query, where: t.descendant in ^descendants
      else
        query
      end
    end
  end
end
