defmodule CTE do
  @moduledoc """
  The Closure Table for Elixir strategy, CTE for short, is a simple and elegant way of storing and working with hierarchies. It involves storing all paths through a tree, not just those with a direct parent-child relationship. You may want to chose this model, over the [Nested Sets model](https://en.wikipedia.org/wiki/Nested_set_model), should you need referential integrity and to assign nodes to multiple trees.

  With CTE you can navigate through hierarchies using a simple [API](CTE.Adapter.html#functions), such as: finding the ascendants and descendants of a node, inserting and deleting nodes, moving entire sub-trees or print them as a digraph (.dot) file.

  ### Quick example.

  For this example we're using the in-[Memory Adapter](CTE.Adapter.Memory.html#content). This `Adapter` is useful for prototyping or with data structures that can easily fit in memory;  their persistence being taken care of by other components. For more involved use cases, CTE integrates with Ecto using a simple API.

  When used from a module, the CTE expects the: `:otp_app` and `:adapter` attributes, to be defined. The `:otp_app` should point to an OTP application that might provide additional configuration. Equally so are the: `:nodes` and the `:paths` attributes. The `:nodes` attribute, in the case of the [Memory Adapter](CTE.Adapter.Memory.html#content), is a Map defining your nodes while the: `:paths` attribute, is a list containing the tree path between the nodes - a list of lists. For example:

      defmodule CTM do
        use CTE,
          otp_app: :ct_empty,
          adapter: CTE.Adapter.Memory,
          nodes: %{
            1 => %{id: 1, author: "Olie", comment: "Is Closure Table better than the Nested Sets?"},
            2 => %{id: 2, author: "Rolie", comment: "It depends. Do you need referential integrity?"},
            3 => %{id: 3, author: "Olie", comment: "Yeah."}
          },
          paths: [[1, 1, 0], [1, 2, 1], [1, 3, 2], [2, 2, 0], [2, 3, 1], [3, 3, 0]]
      end


  When using the `CTE.Adapter.Ecto`, the: `:nodes` attribute, will be a Schema i.e. `Post`, `TreePath`, etc! In our initial implementation, the nodes definitions must have at least the `:id`, as one of their properties. This caveat will be lifted in a later implementation.

  Add the `CTM` module to your main supervision tree:

      defmodule CTM.Application do
        @moduledoc false

        use Application

        def start(_type, _args) do
          opts = [strategy: :one_for_one, name: CTM.Supervisor]

          Supervisor.start_link([CTM], opts)
        end
      end

  Using `iex -S mix`, for quickly experimenting with the CTE API:

  - find the descendants of comment #1

      ```elixir
      iex» CTM.descendants(1)
      {:ok, [3, 2]}
      ```

  - find the ancestors

      ```elixir
      iex» CTM.ancestors(2)
      {:ok, [1]}

      iex» CTM.ancestors(3)
      {:ok, [1]}
      ```
  - find the ancestors, with information about the node:

      ```elixir
      iex» CTM.ancestors(2, nodes: true)
      {:ok,
      [
        %{
          author: "Olie",
          comment: "Is Closure Table better than the Nested Sets?",
          id: 1
        }
      ]}
      ```
  - move leafs/subtrees around. From being a child of comment #1, to becoming a
  child of comment #2, in the following example:

      ```elixir
      iex» CTM.move(3, 2, limit: 1)
      :ok
      iex» CTM.descendants(2)
      {:ok, [3]}
      ```

  Please check the docs, the tests, and the examples folder, for more details.
  """

  @type config :: Keyword.t()

  @type table :: String.t() | atom
  @type nodes :: map() | table
  @type paths :: [list()] | table
  @type repo :: Ecto.Repo | map()
  @type name :: String.t() | atom

  @type t :: %__MODULE__{
          adapter: any() | nil,
          nodes: nodes | nil,
          paths: paths | nil,
          repo: repo | nil,
          name: name | nil
        }
  defstruct [:nodes, :paths, :adapter, :repo, :name]

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @default_adapter CTE.Adapter.Memory
      @default_config [nodes: [], paths: [], adapter: @default_adapter, repo: nil]
      @default_dynamic_supervisor opts[:default_dynamic_supervisor] || opts[:name] || __MODULE__

      @otp_app Keyword.fetch!(opts, :otp_app)
      @adapter Keyword.fetch!(opts, :adapter)
      @opts opts

      @doc false
      def config(), do: parse_config(@opts)

      @doc false
      def __adapter__ do
        {{:repo, _repo}, %{pid: adapter}} = CTE.Registry.lookup(get_dynamic_supervisor())
        adapter
      end

      @doc false
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      @doc false
      def start_link(opts \\ []) do
        CTE.Supervisor.start_link(__MODULE__, @otp_app, @adapter, config())
      end

      @compile {:inline, get_dynamic_supervisor: 0}

      def get_dynamic_supervisor() do
        Process.get({__MODULE__, :dynamic_supervisor}, @default_dynamic_supervisor)
      end

      def put_dynamic_supervisor(dynamic) when is_atom(dynamic) or is_pid(dynamic) do
        Process.put({__MODULE__, :dynamic_supervisor}, dynamic) || @default_dynamic_supervisor
      end

      def insert(leaf, ancestor, opts \\ [])

      def insert(leaf, ancestor, opts), do: @adapter.insert(__adapter__(), leaf, ancestor, opts)

      def tree(leaf, opts \\ [])

      def tree(leaf, opts), do: @adapter.tree(__adapter__(), leaf, opts)

      def ancestors(descendant, opts \\ [])

      def ancestors(descendant, opts), do: @adapter.ancestors(__adapter__(), descendant, opts)

      def descendants(ancestor, opts \\ [])

      def descendants(ancestor, opts), do: @adapter.descendants(__adapter__(), ancestor, opts)

      @doc """
      when limit: 1, the default value, then delete only the leafs, else the entire subtree
      """
      def delete(leaf, ops \\ [])
      def delete(leaf, opts), do: @adapter.delete(__adapter__(), leaf, opts)

      def move(leaf, ancestor, opts \\ [])

      def move(leaf, ancestor, opts), do: @adapter.move(__adapter__(), leaf, ancestor, opts)

      defp parse_config(config), do: CTE.parse_config(@otp_app, __MODULE__, @opts, config)
    end
  end

  @doc false
  def parse_config(otp_app, adapter, adapter_config, dynamic_config) do
    conf =
      Application.get_env(otp_app, adapter, [])
      |> Keyword.merge(adapter_config)
      |> Keyword.merge(dynamic_config)
      |> CTE.interpolate_env_vars()

    %CTE{
      nodes: Keyword.get(conf, :nodes, []),
      paths: Keyword.get(conf, :paths, []),
      repo: Keyword.get(conf, :repo, nil),
      adapter: Keyword.get(conf, :adapter),
      name: Keyword.get(conf, :name)
    }
  end

  @doc false
  def interpolate_env_vars(config) do
    Enum.map(config, fn
      {key, {:system, env_var}} -> {key, System.get_env(env_var)}
      {key, value} -> {key, value}
    end)
  end
end
