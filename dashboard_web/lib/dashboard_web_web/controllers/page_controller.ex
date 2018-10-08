defmodule DashboardWebWeb.PageController do
  use DashboardWebWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
