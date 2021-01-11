defmodule Dashboard.Weather do
  @moduledoc """
  a process service for the weather so we can handle
  error more gracefully and make the update async
  """
  use GenServer
  require Logger
  alias Dashboard.Weather.Retriever

  @weather_refresh_delay 1_800_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Get an image from the index file generated
  def retrieve() do
    GenServer.call(__MODULE__, :retrieve)
  end

  def init(_) do
    state = %{daily: [], hourly: []}
    {:ok, state, {:continue, :init_search}}
  end

  def handle_call(:retrieve, _from, state) do
    {:reply, state, state}
  end

  def handle_continue(:init_search, state) do
    {lat, long} = location()

    case Retriever.retrieve(lat, long) do
      {:ok, data} ->
        state = Map.merge(state, data)

      {:error, error} ->
        Logger.warn(fn -> inspect(error) end)
    end

    # initial schedule to refresh
    Process.send_after(self(), :update_weather, @weather_refresh_delay)
    {:noreply, state}
  end

  def handle_info(:update_weather, state) do
    Process.send_after(self(), :update_weather, @weather_refresh_delay)

    {lat, long} = location()

    case Retriever.retrieve(lat, long) do
      {:ok, data} ->
        state = Map.merge(state, data)

      {:error, error} ->
        Logger.warn(fn -> inspect(error) end)
    end

    {:noreply, state}
  end

  defp time_zone() do
    "America/Los_Angeles"
  end

  defp location() do
    # Seattle
    {47.5599289, -122.2984476}
  end
end
