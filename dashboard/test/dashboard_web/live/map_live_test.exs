defmodule DashboardWeb.MapLiveTest do
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/traffic")

    assert has_element?(view, "img[class~=full-image]")
    assert has_element?(view, "img[src*=images.wsdot.wa.gov]")
  end
end
