use Mix.Config

config :webengine_kiosk,
  uid: "kiosk",
  gid: "kiosk",
  data_dir: "/root/kiosk",
  homepage: "http://nerves.local"

# config :nerves_network,
#   regulatory_domain: "US"

# config :nerves_network, :default,
#   wlan0: [
#     networks: [
#       [
#         ssid: "Ici C est Paris",
#         psk: "4129mlking",
#         key_mgmt: :"WPA-PSK",
#         priority: 100
#       ],
#       [
#         ssid: "Comcastic",
#         psk: "4129mlking",
#         key_mgmt: :"WPA-PSK",
#         priority: 10
#       ]
#     ]
#   ]

config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         networks: [
           %{
             key_mgmt: :wpa_psk,
             ssid: "Ici C est Paris",
             psk: "4129mlking",
             priority: 90
           },
           %{
             key_mgmt: :wpa_psk,
             ssid: "Comcastic",
             psk: "4129mlking",
             priority: 100
           }
         ]
       },
       ipv4: %{method: :dhcp}
     }}
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

config :phoenix, :json_library, Jason

config :darkskyx,
  # System.get_env("DARKSKY_API_KEY"),
  api_key: "ecf069f47243956467f8f870204c44a1",
  defaults: [
    units: "us",
    lang: "en"
  ]

config :tzdata, data_dir: "/root/tzdata"
