use Mix.Config

# Do not include metadata nor timestamps
config :logger, :console, format: "[$level] $message\n"
config :logger, :level, :error

config :ct, CT.Repo,
  database: "ct_ecto_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox
