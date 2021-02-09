defmodule DashboardWeb.MenuLiveTest do
  @moduledoc false
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "<div class=\"weather-heading\">"

    # view
    # |> element("#show-profile")
    # |> render_click()

    # assert has_element?(view, "img[src*=#{user.avatar_url}]")
  end
end
