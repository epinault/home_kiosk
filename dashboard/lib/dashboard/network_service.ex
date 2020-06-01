defmodule Dashboard.NetworkService do
  use GenServer
  require Logger

  # Public API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Get an image from the index file generated
  def ready!() do
    GenServer.call(__MODULE__, :ready_state)
  end

  def ready?() do
    GenServer.call(__MODULE__, :check_state) == :ready
  end

  def init(_) do
    init_state = :pending

    # if Mix.target() == :host do
    #   :ready
    # else
    #   :pending
    # end

    {:ok, init_state}
  end

  def handle_call(:check_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:ready_state, _from, _state) do
    {:reply, :ok, :ready}
  end
end
