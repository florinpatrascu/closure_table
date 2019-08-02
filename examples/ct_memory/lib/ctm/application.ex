defmodule CTM.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: CTM.Supervisor]

    Supervisor.start_link([CTM], opts)
  end
end
