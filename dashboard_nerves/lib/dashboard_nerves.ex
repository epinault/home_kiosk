defmodule DashboardNerves do
  @moduledoc """
  Documentation for DashboardNerves.
  """

  @doc """
  Hello world.

  ## Examples

      iex> DashboardNerves.hello
      :world

  """
  require Logger

  def hello do
    Logger.debug("hello")
    :world
  end
end
