defmodule DashboardWeb.SlideshowLive do
  use Phoenix.LiveView
  alias Dashboard.ImageService
  @refresh_delay 30000

  def render(assigns) do
    Phoenix.View.render(DashboardWeb.PageView, "slideshow_live.html", assigns)
  end

  def mount(_params, session, socket) do
    image = get_image_url()

    if connected?(socket),
      do: Process.send_after(self(), {:change_image, image}, @refresh_delay)

    {:ok, assign(socket, image: image)}
  end

  def handle_info({:change_image, image}, socket) do
    Process.send_after(self(), {:change_image, get_image_url()}, @refresh_delay)
    {:noreply, assign(socket, image: image)}
  end

  defp get_image_url do
    ImageService.rand_image_url()
  end
end