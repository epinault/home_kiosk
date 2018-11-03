# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget, :nerves_network],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

key = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
unless File.exists?(key), do: Mix.raise("No SSH Keys found. Please generate an ssh key")

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(key)
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcpd,
  mdns_domain: "nerves.local",
  node_name: "kiosk",
  node_host: :mdns_domain,
  ssh_console_port: 22

config :webengine_kiosk,
  uid: "kiosk",
  gid: "kiosk",
  data_dir: "/root/kiosk",
  homepage: "http://localhost"

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

config :nerves_network,
  regulatory_domain: "US"

config :nerves_network, :default,
  wlan0: [
    # System.get_env("Ici c est Paris"),
    ssid: "Ici c est Paris",
    # System.get_env("NERVES_NETWORK_PSK"),
    psk: "4129mlking",
    # String.to_atom(System.get_env("NERVES_NETWORK_MGMT"))
    key_mgmt: :"WPA-PSK"
  ]

# import_config "#{Mix.Project.config[:target]}.exs"
