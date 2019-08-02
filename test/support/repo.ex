defmodule CTE.Repo do
  use Ecto.Repo,
    otp_app: :cte,
    adapter: Ecto.Adapters.Postgres
end
