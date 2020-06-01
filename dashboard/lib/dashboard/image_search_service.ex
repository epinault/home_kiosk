defmodule Dashboard.ImageSearchService do
  use GenServer
  require Logger
  alias Dashboard.DuckduckgoSearch
  alias Dashboard.NetworkService

  # Public API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Get an image from the index file generated
  def rand_image() do
    GenServer.call(__MODULE__, :rand_image)
  end

  def init(_) do
    keywords = "dragon ball"
    {:ok, %{keywords: keywords, images: []}, {:continue, :init_search}}
  end

  def handle_call(:rand_image, _from, state) do
    image = Enum.random(state[:images])
    {:reply, image, state}
  end

  def handle_info(:retry, state) do
    state = Map.merge(state, %{images: load_images(state)})
    {:noreply, state}
  end

  def handle_continue(:init_search, state) do
    state = Map.merge(state, %{images: load_images(state)})
    {:noreply, state}
  end

  defp load_images(state) do
    if NetworkService.ready?() do
      case DuckduckgoSearch.search_images(state[:keywords]) do
        {:ok, images} ->
          images

        _ ->
          # if any failure, we just ignore it and keep the previous state
          Logger.error("Failed to load new images from DuckDuckgo..")
          state[:images]
      end
    else
      Logger.warn("Not connected yet. Retrying in 5 seconds")
      Process.send_after(self(), :retry, 5000)
      state[:images]
    end
  end
end
