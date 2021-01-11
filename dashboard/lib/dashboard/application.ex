defmodule Dashboard.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the endpoint when the application starts
      {Phoenix.PubSub, name: Dashboard.PubSub},
      DashboardWeb.Endpoint,
      Dashboard.NetworkService,
      Dashboard.Backlight,
      Dashboard.Weather,
      {Dashboard.ImageService,
       name: Dashboard.PersonalImages, retriever: Dashboard.ImageService.StaticList},
      {Dashboard.ImageService,
       name: Dashboard.GokuImages,
       retriever: Dashboard.ImageService.DynamicList,
       keywords: "dragon ball"},
      Dashboard.MenuService
    ]

    opts = [strategy: :one_for_one, name: Dashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
