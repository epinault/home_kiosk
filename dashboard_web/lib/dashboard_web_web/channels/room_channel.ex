defmodule DashboardWebWeb.RoomChannel do
  use Phoenix.Channel
  require Logger

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

  # def handle_in("new:msg", msg, socket) do
  #   broadcast!(socket, "new:msg", %{user: msg["user"], body: msg["body"]})
  #   {:reply, {:ok, %{msg: msg["body"]}}, assign(socket, :user, msg["user"])}
  # end
end
