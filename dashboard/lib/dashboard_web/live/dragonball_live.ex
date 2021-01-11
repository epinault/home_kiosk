defmodule DashboardWeb.DragonballLive do
  @moduledoc false
  use Phoenix.LiveView
  alias Dashboard.ImageSearchService

  @refresh_rate 30_000

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "dragonball_live.html", assigns)
  end

  def mount(_params, _session, socket) do
    image = get_image()

    if connected?(socket),
      do: Process.send_after(self(), :change_image, @refresh_rate)

    {:ok, assign(socket, image: image)}
  end

  def handle_info(:change_image, socket) do
    image = get_image()
    Process.send_after(self(), :change_image, @refresh_rate)

    {:noreply, assign(socket, :image, image)}
  end

  defp get_image() do
    Dashboard.ImageService.rand_image(Dashboard.GokuImages)
  end
end
