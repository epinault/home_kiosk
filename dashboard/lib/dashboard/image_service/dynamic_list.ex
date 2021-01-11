defmodule Dashboard.ImageService.DynamicList do
  @moduledoc """
  This is a dynamic loader of images list. Currently
  only support DuckDuckGoSearch for images
  """
  @behaviour Dashboard.ImageService.Retriever
  require Logger

  alias Dashboard.ImageService.DuckduckgoSearch

  def load_images(state) do
    case DuckduckgoSearch.search_images(state[:keywords]) do
      {:ok, images} ->
        images

      _ ->
        # if any failure, we just ignore it and keep the previous state
        Logger.error("Failed to load new images from DuckDuckgo..")
        state[:images]
    end
  end
end
