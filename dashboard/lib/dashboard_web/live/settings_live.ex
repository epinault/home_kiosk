defmodule DashboardWeb.SettingsLive do
  @moduledoc false

  use Phoenix.LiveView
  alias Dashboard.Backlight

  @from_range 1..100
  @to_range 15..255

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "settings_live.html", assigns)
  end

  def mount(_params, session, socket) do
    brightness = map_range(@to_range, @from_range, Backlight.brightness())

    {:ok, assign(socket, brightness: brightness)}
  end

  def handle_event("config-changed", params, socket) do
    map_range(@from_range, @to_range, String.to_integer(params["brightness"]))
    |> Backlight.set_brightness()

    {:noreply, assign(socket, brightness: params["brightness"])}
  end

  def map_range(a1..a2, b1..b2, s) do
    b1 + (s - a1) * (b2 - b1) / (a2 - a1)
  end
end
