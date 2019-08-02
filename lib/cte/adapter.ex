defmodule CTE.Adapter do
  @moduledoc ~S"""
  Specification of the Closure Table implementation.

  Most of the functions implementing the `CTE.Adapter` behavior, will accept the following options:

  - `:limit`, to limit the total number of nodes returned, when finding the ancestors or the descendants for nodes
  - `:itself`, accepting a boolean value. When `true`, the node used for finding its neighbors are returned as part of the results. Default: true
  - `:nodes`, accepting a boolean value. When `true`, the results are containing additional information about the nodes. Default: false

  """
  @type t :: module
  @type options :: Keyword.t()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer
      @behaviour CTE.Adapter

      @doc """
      start the Adapter server
      """
      def start_link(init_args) do
        GenServer.start_link(__MODULE__, init_args)
      end

      @doc """
      Initializes the adapter supervision tree by returning the children and adapter metadata.
      """
      def init(repo: _repo, config: config) do
        {:ok, config}
      end

      defoverridable start_link: 1, init: 1
    end
  end

  @doc """
  Retrieve the descendants of a node
  """
  @callback descendants(pid(), ancestor :: any(), options) :: {:ok, CTE.nodes()} | {:error, any()}

  @doc """
  Retrieve the ancestors of a node
  """
  @callback ancestors(pid(), descendant :: any(), options) :: {:ok, CTE.nodes()} | {:error, any()}

  @doc """
  Delete a leaf or a subtree.
  When limit: 1, the default value, then delete only the leafs, else the entire subtree
  """
  @callback delete(pid(), leaf :: any(), options) :: :ok | {:error, any()}

  @doc """
  Insert a node under an existing ancestor
  """
  @callback insert(pid(), leaf :: any(), ancestor :: any(), options) ::
              {:ok, CTE.t()} | {:error, any()}

  @doc """
  Move a subtree from one location to another.

  First, the subtree and its descendants are disconnected from its ancestors. And second, the subtree is inserted under the new parent (ancestor) and the subtree, including its descendants, is declared as descendants of all the new ancestors.
  """
  @callback move(pid(), leaf :: any(), ancestor :: any(), options) :: :ok | {:error, any()}

  @doc """
  Calculate and return a "tree" structure containing the paths and the nodes under the given leaf/node
  """
  @callback tree(pid(), leaf :: any(), options) :: {:ok, CTE.nodes()} | {:error, any()}

  @doc false
  def lookup_meta(repo_name_or_pid) do
    {_, meta} = CTE.Registry.lookup(repo_name_or_pid)
    meta
  end
end
