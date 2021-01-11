defmodule Dashboard.ImageService.StaticList do
  @moduledoc """
  This is a static loader of images from a file that is local
  and point to remote personal server
  """

  @behaviour Dashboard.ImageService.Retriever
  require Logger

  @index_file "images.txt"

  def load_images(state) do
    filename = Path.join([:code.priv_dir(:dashboard), "static", @index_file])

    case File.read(filename) do
      {:ok, buffer} ->
        for image_name <- String.split(buffer, "\n"), do: image_url(image_name)

      {:error, error} ->
        Logger.error(fn -> "#{inspect(error)}" end)
        state[:images]
    end
  end

  def image_url(image_name) do
    "https://images.pinault-family.us/#{image_name}"
  end
end
