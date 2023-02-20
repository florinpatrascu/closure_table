Code.require_file("./support/migration.exs", __DIR__)

# Ensure test database is created and the migrations have run
Application.put_env(:closure_table, CTE.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ct_ecto_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  log: false
)

_ = CTE.Repo.__adapter__().storage_down(CTE.Repo.config())
:ok = CTE.Repo.__adapter__().storage_up(CTE.Repo.config())
CTE.Repo.__adapter__().storage_up(CTE.Repo.config())
{:ok, _} = CTE.Repo.start_link()
Ecto.Migrator.up(CTE.Repo, 0, CTE.Migration)

ExUnit.start()
