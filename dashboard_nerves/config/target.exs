use Mix.Config

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcpd,
  mdns_domain: "nerves.local",
  node_name: "kiosk",
  node_host: :mdns_domain,
  ssh_console_port: 22
