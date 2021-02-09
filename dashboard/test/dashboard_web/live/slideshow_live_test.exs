defmodule DashboardWeb.SlideshowLiveTest do
  @moduledoc false
  use DashboardWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mockery
  import Mockery.Assertions

  alias Dashboard.ImageService

  test "renders the slideshow page", %{conn: conn} do
    mock(ImageService, :rand_image, "myimgurl")

    {:ok, view, _} = live(conn, "/slideshow")

    assert has_element?(view, "div[class*=full-image-wrapper]")
    assert has_element?(view, "img[class*=full-image]")

    assert_called(ImageService, :rand_image)
  end
end
