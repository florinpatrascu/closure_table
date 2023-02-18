import Config

config :ct,
  ecto_repos: [CT.Repo],
  migration_timestamps: [
    type: :utc_datetime
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
