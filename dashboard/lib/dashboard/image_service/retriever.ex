defmodule Dashboard.ImageService.Retriever do
  @moduledoc """
  Interface for all Image retrievers
  """
  @callback load_images(map()) :: {:ok, list()} | {:error, list()}

  def retrieve(retriever, state) do
    retriever.load_images(state)
  end
end
