defmodule Dashboard.Menu do
  use HTTPoison.Base
  alias Dashboard.Menu

  @base_url "https://images.pinault-family.us"

  def load_menus() do
    with {:ok, body} <- initial_request("/menu.json"),
         {:ok, menus} <- parse_menus(body) do
      {:ok, menus}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def process_request_url(url) do
    @base_url <> url
  end

  defp initial_request(uri) do
    case Menu.get!(uri) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}

      %HTTPoison.Error{reason: reason} ->
        {:error, reason}

      _ ->
        {:error, :failed_to_load_menus}
    end
  end

  defp parse_menus(body) do
    resp = Jason.decode!(body)
    {:ok, resp}
  end
end
