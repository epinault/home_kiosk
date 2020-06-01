defmodule Dashboard.ImageService do
  use GenServer
  require Logger
  alias Dashboard.ImageService

  @index_file "images.txt"

  # Public API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Get an image from the index file generated
  def rand_image() do
    GenServer.call(__MODULE__, :rand_image)
  end

  def rand_image_url() do
    "https://images.pinault-family.us/#{ImageService.rand_image()}"
  end

  def init(_) do
    images = load_images()
    {:ok, images}
  end

  def handle_call(:rand_image, _from, images) do
    image = Enum.random(images)
    {:reply, image, images}
  end

  defp load_images do
    filename = Path.join([:code.priv_dir(:dashboard), "static", "images.txt"])

    with {:ok, buffer} <- File.read(filename) do
      String.split(buffer, "\n")
    else
      {:error, error} ->
        Logger.error(fn -> "#{inspect(error)}" end)
        []
    end
  end
end
