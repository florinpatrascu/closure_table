defmodule CTE.Repo do
  use Ecto.Repo,
    otp_app: :closure_table,
    adapter: Ecto.Adapters.Postgres
end
