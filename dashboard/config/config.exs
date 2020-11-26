# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :dashboard, DashboardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "8vgemohuRC3kPBi4MqtUfKlTYxKvwzBFM/UBiUGzGSucS1kPAmhaipDdZYCQwmQB",
  render_errors: [view: DashboardWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Dashboard.PubSub,
  live_view: [signing_salt: "pzRkV534"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :darkskyx,
  # System.get_env("DARKSKY_API_KEY"),
  api_key: "ecf069f47243956467f8f870204c44a1",
  defaults: [
    units: "us",
    lang: "en"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
