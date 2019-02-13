use Mix.Config

config :webengine_kiosk,
  uid: "kiosk",
  gid: "kiosk",
  data_dir: "/root/kiosk",
  homepage: "http://localhost"

config :nerves_network,
  regulatory_domain: "US"

config :nerves_network, :default,
  wlan0: [
    # System.get_env("Ici c est Paris"),
    ssid: "Ici c est Paris",
    # System.get_env("NERVES_NETWORK_PSK"),
    psk: "4129mlking",

    # ssid: "Outreach-Guest",
    # System.get_env("NERVES_NETWORK_PSK"),
    # psk: "OutreachTime!",

    # String.to_atom(System.get_env("NERVES_NETWORK_MGMT"))
    key_mgmt: :"WPA-PSK"
  ]

config :dashboard_web, DashboardWebWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 80],
  secret_key_base: "123456",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [view: DashboardWebWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Nerves.PubSub, adapter: Phoenix.PubSub.PG2],
  code_reloader: false,
  check_origin: false

config :darkskyx,
  # System.get_env("DARKSKY_API_KEY"),
  api_key: "a1444104ea5812e15a06c2e086697a1b",
  defaults: [
    units: "us",
    lang: "en"
  ]
