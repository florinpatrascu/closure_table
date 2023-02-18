defmodule CTE.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(mod, otp_app, adapter, cte_config) do
    name = cte_config.name || mod
    Supervisor.start_link(__MODULE__, {mod, otp_app, adapter, cte_config}, name: name)
  end

  def init({mod, _otp_app, adapter, cte_config}) do
    # the otp_app here can be used for grabbing user definitions at runtime
    args = [repo: mod] ++ [config: cte_config]

    child_spec =
      %{
        id: mod,
        start: {adapter, :start_link, [args]}
      }
      |> wrap_child_spec(args)

    Supervisor.init([child_spec], strategy: :one_for_one, max_restarts: 0)
  end

  def start_child({mod, fun, args}, adapter, _meta) do
    case apply(mod, fun, args) do
      {:ok, pid} ->
        CTE.Registry.associate(self(), {adapter, %{pid: pid}})
        {:ok, pid}

      other ->
        other
    end
  end

  defp wrap_child_spec(%{start: start} = spec, args) do
    %{spec | start: {__MODULE__, :start_child, [start | args]}}
  end
end
