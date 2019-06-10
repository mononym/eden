use Mix.Config

# Print only warnings and errors during test
config :logger, :console, level: :warn

config :exmud_account, Exmud.Account.Repo,
  password: "exmud_account",
  pool: Ecto.Adapters.SQL.Sandbox
