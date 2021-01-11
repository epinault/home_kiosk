defmodule Dashboard.ImageService do
  @moduledoc """
  a generic service for caching images details so we can handle
  error more gracefully and make the update async
  """
  use GenServer
  require Logger
  alias Dashboard.DuckduckgoSearch
  alias Dashboard.NetworkService

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # Get an image from the index file generated
  def rand_image(pid) do
    GenServer.call(pid, :rand_image)
  end

  def init(opts) do
    retriever = Keyword.get(opts, :retriever)
    keywords = Keyword.get(opts, :keywords)

    {:ok, %{keywords: keywords, retriever: retriever, images: []}, {:continue, :init_search}}
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
      retriever = state[:retriever]
      retriever.load_images(state)
    else
      Logger.warn("Not connected yet. Retrying in 5 seconds")
      Process.send_after(self(), :retry, 5000)
      state[:images]
    end
  end
end
