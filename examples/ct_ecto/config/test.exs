use Mix.Config

config :ct, CT.Repo,
  database: "cte_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :mix_test_watch,
  clear: true
