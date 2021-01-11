defmodule Dashboard.Weather.Retriever do
  @moduledoc """
  an interface to weather retrievers
  """
  alias Dashboard.Weather.Darksky

  @callback retrieve_data(number(), number()) :: {:ok, any()} | {:error, any()}

  def retrieve(lat, long) do
    retriever().retrieve_data(lat, long)
  end

  def retriever() do
    Application.get_env(:dashboard, :weather_retriever, Darksky)
  end
end
