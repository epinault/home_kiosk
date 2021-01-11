defmodule DashboardWeb.MenuLive do
  @moduledoc false

  use Phoenix.LiveView
  @refresh_delay 600_000

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "menu_live.html", assigns)
  end

  def mount(_params, session, socket) do
    menus = Dashboard.MenuService.next_five_days()

    if connected?(socket),
      do: Process.send_after(self(), :tick, @refresh_delay)

    {:ok, assign(socket, :menus, menus)}
  end

  def handle_info(:tick, socket) do
    menus = Dashboard.MenuService.next_five_days()
    Process.send_after(self(), :tick, @refresh_delay)

    {:noreply, assign(socket, :menus, menus)}
  end
end
