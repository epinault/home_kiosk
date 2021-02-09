defmodule DashboardWeb.DragonballLiveTest do
  @moduledoc false
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mockery
  import Mockery.Assertions

  alias Dashboard.ImageService

  test "renders the dragon ball page", %{conn: conn} do
    mock(ImageService, :rand_image, "myimgurl")
    {:ok, view, html} = live(conn, "/dragonball")

    assert has_element?(view, "div[class*=full-image-wrapper]")
    assert has_element?(view, "img[class*=dbz-image]")

    assert_called(ImageService, :rand_image)
  end
end
