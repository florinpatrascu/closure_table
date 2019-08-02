use Mix.Config

config :ct, CT.Repo,
  database: "cte_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 50

config :mix_test_watch,
  clear: true
