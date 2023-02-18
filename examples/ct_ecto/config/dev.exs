import Config

config :ct, CT.Repo,
  database: "ct_ecto_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 50

config :mix_test_watch,
  clear: true
