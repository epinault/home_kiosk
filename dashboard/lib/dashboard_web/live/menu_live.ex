defmodule DashboardWeb.MenuLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "menu_live.html", assigns)
  end

  def mount(_params, session, socket) do
    # {:ok, assign(socket, :temperature, temperature)}
    {:ok, socket}
  end
end
