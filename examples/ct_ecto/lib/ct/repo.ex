defmodule CT.Repo do
  use Ecto.Repo,
    otp_app: :ct,
    adapter: Ecto.Adapters.Postgres
end
