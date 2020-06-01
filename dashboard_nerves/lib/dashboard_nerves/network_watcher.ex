defmodule DashboardNerves.NetworkWatcher do
  use GenServer
  require Logger
  @subscription ["interface", "wlan0", "connection"]
  @special_client "b8:27:eb:c4:ba:c8"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    VintageNet.subscribe(@subscription)
    {:ok, %{}}
  end

  def handle_info({VintageNet, @subscription, old_value, new_value, metadata}, state) do
    case new_value do
      :internet ->
        Logger.warn("Internet is back! we are good to go")
        Dashboard.NetworkService.ready!()
        WebengineKiosk.go_to_url(Display, "http://localhost/")

      _ ->
        Logger.warn("we are disconnected")
    end

    {:noreply, state}
  end
end
