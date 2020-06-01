defmodule DashboardWeb.IndexLive do
  use Phoenix.LiveView
  @refresh_delay 1_000
  @weather_refresh_delay 1_800_000
  @menu_refresh_delay 1_800_000

  require Logger

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "index_live.html", assigns)
  end

  def mount(_params, session, socket) do
    {:ok, time} = Calendar.DateTime.now("America/Los_Angeles")
    {:ok, formatted_time} = time |> Calendar.Strftime.strftime("%H:%M:%S")

    if connected?(socket) do
      Process.send_after(self(), :update_time, @refresh_delay)
      Process.send_after(self(), :update_today_menu, @menu_refresh_delay)
      Process.send_after(self(), :update_weather, @weather_refresh_delay)
    end

    menu = Dashboard.MenuService.today()

    with {:ok, weather_data} <- Dashboard.Weather.retrieve_data(47.5599289, -122.2984476) do
      {:ok, assign(socket, weather_data: weather_data, menu: menu, time: formatted_time)}
    else
      {:error, error} ->
        Logger.error(fn -> "#{inspect(error)}" end)
        {:ok, assign(socket, weather_data: %{:daily => []}, time: formatted_time)}
    end
  end

  def handle_info(:update_time, socket) do
    Process.send_after(self(), :update_time, @refresh_delay)

    {:ok, time} = Calendar.DateTime.now("America/Los_Angeles")
    {:ok, formatted_time} = time |> Calendar.Strftime.strftime("%H:%M:%S")

    {:noreply, assign(socket, time: formatted_time)}
  end

  def handle_info(:update_weather, socket) do
    Process.send_after(self(), :update_weather, @weather_refresh_delay)

    weather_data = Dashboard.Weather.retrieve_data(47.5599289, -122.2984476)

    {:ok, time} = Calendar.DateTime.now("America/Los_Angeles")
    {:ok, formatted_time} = time |> Calendar.Strftime.strftime("%H:%M:%S")

    {:noreply, assign(socket, weather_data: weather_data, time: formatted_time)}
  end

  def handle_info(:update_today_menu, socket) do
    Process.send_after(self(), :update_today_menu, @menu_refresh_delay)

    {:ok, time} = Calendar.DateTime.now("America/Los_Angeles")
    menu = Dashboard.MenuService.today()

    {:noreply, assign(socket, menu: menu)}
  end
end
