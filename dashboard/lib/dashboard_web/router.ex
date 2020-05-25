defmodule DashboardWeb.Router do
  use DashboardWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {DashboardWeb.LayoutView, :root})
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", DashboardWeb do
    pipe_through(:browser)

    live("/", IndexLive)
    live("/slideshow", SlideshowLive)
    live("/menu", MenuLive)
    live("/dragonball", DragonballLive)
    live("/traffic", MapLive)
    live("/settings", SettingsLive)
    live_dashboard("/dashboard")
  end
end
