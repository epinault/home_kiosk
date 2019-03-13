defmodule DashboardWebWeb.RoomChannel do
  use Phoenix.Channel
  require Logger

  @from_range 1..100
  @to_range 15..255

  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    # send(self, {"weather:update", message})
    send(self(), "weather:update")

    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  # def handle_info({:after_join, msg}, socket) do
  #   broadcast!(socket, "user:entered", %{user: msg["user"]})
  #   push(socket, "join", %{status: "connected"})
  #   {:noreply, socket}
  # end

  # def handle_info(:ping, socket) do
  #   push(socket, "new:msg", %{user: "SYSTEM", body: "ping"})
  #   {:noreply, socket}
  # end

  def handle_in("brightness", %{"value" => value} = payload, socket) do
    Logger.debug("Brightness: #{inspect(value)}")
    broadcast(socket, "brightness", payload)

    map_range(@from_range, @to_range, value)
    |> DashboardWeb.Backlight.set_brightness()

    {:noreply, socket}
  end

  def handle_info("weather:update", socket) do
    res = DashboardWeb.Weather.render(47.5599289, -122.2984476)
    push(socket, "weather:update", %{msg: res})
    Process.send_after(self(), "weather:update", 600_000)

    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug("> leave #{inspect(reason)}")
    :ok
  end

  defp map_range(a1..a2, b1..b2, s) do
    b1 + (s - a1) * (b2 - b1) / (a2 - a1)
  end
end
