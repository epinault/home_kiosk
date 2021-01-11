defmodule Dashboard.MenuService do
  @moduledoc """
  A menu service handler. So we can handle loading, and caching
  the menu
  """
  use GenServer
  require Logger
  alias Dashboard.NetworkService
  alias Dashboard.Menu

  # Public API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Get an image from the index file generated
  def today() do
    GenServer.call(__MODULE__, :today)
  end

  def next_five_days() do
    GenServer.call(__MODULE__, :next_five_days)
  end

  def init(_) do
    {:ok,
     %{
       status: :loading,
       today: %{},
       menus: []
     }, {:continue, :init_load_menu}}
  end

  def handle_call(:today, _from, state) do
    menu = state[:today]
    {:reply, menu, state}
  end

  def handle_call(:next_five_days, _from, state) do
    menus = state[:menus]
    {:reply, menus, state}
  end

  def handle_info(:retry, state) do
    state = load_menu(state)
    {:noreply, state}
  end

  def handle_continue(:init_load_menu, state) do
    state = load_menu(state)
    {:noreply, state}
  end

  defp load_menu(state) do
    if NetworkService.ready?() do
      case Menu.load_menus() do
        {:ok, menus} ->
          today = find_today(menus)
          Map.merge(state, %{status: :ready, menus: menus, today: today})

        _ ->
          # if any failure, we just ignore it and keep the previous state
          Logger.error("Failed to load new images from DuckDuckgo..")
          state
      end
    else
      Logger.warn("Not connected yet. Retrying in 5 seconds")
      Process.send_after(self(), :retry, 5000)
      state
    end
  end

  defp find_today(menus) do
    {:ok, today} =
      Calendar.Date.today!("America/Los_Angeles") |> Calendar.Strftime.strftime("%Y-%m-%d")

    Enum.find(menus, fn menu ->
      menu["date"] == today
    end)
  end
end
