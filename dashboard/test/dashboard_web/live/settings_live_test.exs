defmodule DashboardWeb.SettingsLiveTest do
  @moduledoc false
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the settings page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/settings")

    assert render(view) =~ "<p>Screen brightness</p>"
    assert has_element?(view, "input[class*=slider]")
  end

  # test "can change the slider settings", %{conn: conn} do
  #   {:ok, view, _html} = live(conn, "/settings")

  #   assert render(view) =~ "<p>Screen brightness</p>"
  #   assert has_element?(view, "input[class*=slider]")
  # end
end
