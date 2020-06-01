defmodule DashboardNerves.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.target()

  use Application

  def start(_type, _args) do
    platform_init(@target)

    webengine_kiosk_opts = Application.get_all_env(:webengine_kiosk)

    children = [
      {WebengineKiosk, {webengine_kiosk_opts, [name: Display]}}
      | children(@target)
    ]

    opts = [strategy: :one_for_one, name: DashboardNerves.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children("host") do
    webengine_opts = Application.get_all_env(:webengine_kiosk)

    [
      # {WebengineKiosk, {webengine_opts, name: Display}}
    ]
  end

  def children(_target) do
    webengine_opts = Application.get_all_env(:webengine_kiosk)

    [
      DashboardNerves.NetworkWatcher
      # {WebengineKiosk, {webengine_opts, name: Display}}
    ]
  end

  defp platform_init("host"), do: :ok

  defp platform_init(_target) do
    # Initialize udev
    :os.cmd('udevd -d')
    :os.cmd('udevadm trigger --type=subsystems --action=add')
    :os.cmd('udevadm trigger --type=devices --action=add')
    :os.cmd('udevadm settle --timeout=30')

    # Workaround a known bug with HTML5 canvas and rpi gpu

    System.put_env("QTWEBENGINE_CHROMIUM_FLAGS", "--disable-gpu")
    System.put_env("QTWEBENGINE_REMOTE_DEBUGGING", "9222")
    MuonTrap.Daemon.start_link("socat", ["tcp-listen:9223,fork", "tcp:localhost:9222"])
  end
end
