defmodule Dashboard.NetworkService do
  @moduledoc """
  A simple abstraction to know wehter we have network access or not
  in the raspberry pi. In the nerves code, we listen for UP of an interface
  and then we call the ready! to tell that we are ready

  Useful for startup race condition but we need to handle also
  when network goes up and down (though we tend to cache stuff so
  most pages will load)
  """
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
