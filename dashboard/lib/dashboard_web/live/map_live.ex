defmodule DashboardWeb.MapLive do
  use Phoenix.LiveView
  @refresh_delay 60_000

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "map_live.html", assigns)
  end

  def mount(_params, session, socket) do
    image = get_image_url()
    Process.send_after(self(), {:change_image, image}, @refresh_delay)
    {:ok, assign(socket, url: image)}
  end

  def handle_info({:change_image, image}, socket) do
    Process.send_after(self(), {:change_image, get_image_url()}, @refresh_delay)
    {:noreply, assign(socket, url: image)}
  end

  defp get_image_url do
    timestamp = DateTime.utc_now()

    "https://images.wsdot.wa.gov/nwflow/flowmaps/bridges.gif?#{timestamp}"
  end
end
