defmodule DashboardWeb.IndexLiveTest do
  @moduledoc false
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the home page and the weather", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "div[class*=weather-heading]")
    assert has_element?(view, "div[class*=box weather-box]")
  end

  test "renders the location", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "<span>Seattle"
  end

  test "renders the traffic", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "div[class*=box traffic-box]")
    assert has_element?(view, "img[src*=images.wsdot.wa.gov]")
  end

  test "renders the lunch box", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "div[class*=box lunch-box]")
  end

  test "renders the dinner box", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "div[class*=box dinner-box]")
  end
end
