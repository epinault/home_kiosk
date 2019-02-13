# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :dashboard_web, DashboardWebWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "2PdBdkSokXc9JJHgIu0Yv5Vhgy0/5Tm9I5uxX/FkX0IgyM4/becbaA6aX78Oll1e",
  render_errors: [view: DashboardWebWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DashboardWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :darkskyx,
  # System.get_env("DARKSKY_API_KEY"),
  api_key: "a1444104ea5812e15a06c2e086697a1b",
  defaults: [
    units: "us",
    lang: "en"
  ]

config :phoenix, :json_library, Jason
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
