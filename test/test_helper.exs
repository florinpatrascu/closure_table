Code.require_file("./support/migration.exs", __DIR__)

# Ensure test database is created and the migrations have run
CTE.Repo.__adapter__().storage_up(CTE.Repo.config())
{:ok, _} = CTE.Repo.start_link()
Ecto.Migrator.up(CTE.Repo, 0, CTE.Migration, log: false)

ExUnit.start()
