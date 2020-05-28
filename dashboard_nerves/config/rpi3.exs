use Mix.Config

config :webengine_kiosk,
  uid: "kiosk",
  gid: "kiosk",
  data_dir: "/root/kiosk",
  homepage: "http://nerves.local"

config :nerves_network,
  regulatory_domain: "US"

config :nerves_network, :default,
  wlan0: [
    networks: [
      [
        ssid: "Ici C est Paris",
        psk: "4129mlking",
        key_mgmt: :"WPA-PSK",
        priority: 100
      ],
      [
        ssid: "Comcastic",
        psk: "4129mlking",
        key_mgmt: :"WPA-PSK",
        priority: 10
      ]
    ]
  ]

config :dashboard, DashboardWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 80],
  secret_key_base: "8vgemohuRC3kPBi4MqtUfKlTYxKvwzBFM/UBiUGzGSucS1kPAmhaipDdZYCQwmQB",
  render_errors: [view: DashboardWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Dashboard.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "pzRkV534"],
  server: true,
  code_reloader: false,
  check_origin: false,
  root: Path.dirname(__DIR__)

# config :dashboard, DashboardWeb.Endpoint,
#   url: [host: "localhost"],
#   http: [port: 80],
#   secret_key_base: "123456",
#   root: Path.dirname(__DIR__),

config :darkskyx,
  # System.get_env("DARKSKY_API_KEY"),
  api_key: "a1444104ea5812e15a06c2e086697a1b",
  defaults: [
    units: "us",
    lang: "en"
  ]

config :tzdata, data_dir: "/root/tzdata"
