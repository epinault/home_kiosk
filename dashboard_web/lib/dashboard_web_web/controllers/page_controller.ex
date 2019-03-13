defmodule DashboardWebWeb.PageController do
  use DashboardWebWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def recipes(conn, _params) do
    render(conn, "recipes.html")
  end

  def settings(conn, _params) do
    render(conn, "settings.html")
  end
end
