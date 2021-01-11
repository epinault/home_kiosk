defmodule Dashboard.ImageService.DuckduckgoSearch do
  @moduledoc """
  DuckDuckGo Images Search retriever
  """
  use HTTPoison.Base
  alias Dashboard.ImageService.DuckduckgoSearch

  @base_url "https://duckduckgo.com"

  def search_images(query) do
    with {:ok, body} <- initial_request(query),
         {:ok, vqd} <- parse_vqd(body),
         {:ok, body} <- find_matching_images(query, vqd),
         {:ok, images} <- parse_image_results(body) do
      {:ok, images}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def process_request_url(url) do
    @base_url <> url
  end

  defp initial_request(query) do
    url = "/?#{URI.encode_query(%{q: query})}"

    case DuckduckgoSearch.get!(url) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}

      %HTTPoison.Error{reason: reason} ->
        {:error, reason}

      _ ->
        {:error, :failed_to_load_vqd}
    end
  end

  defp parse_vqd(body) do
    matches = Regex.run(~r/vqd='(.+?)'/, body)

    case matches do
      nil ->
        {:error, :vqd_not_found}

      _ ->
        {:ok, List.last(matches)}
    end
  end

  defp find_matching_images(query, vqd) do
    url = image_search_url(query, vqd)

    case DuckduckgoSearch.get!(url) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}

      %HTTPoison.Error{reason: reason} ->
        {:error, reason}

      _ ->
        {:error, "could not load the page"}
    end
  end

  defp image_search_url(query, vqd) do
    encoded_terms =
      URI.encode_query(%{
        l: "us-en",
        o: "json",
        q: query,
        vqd: vqd,
        f: "size:Large,type:photo,layout:Wide,",
        p: "1",
        v7exp: "a",
        sltexp: "b"
      })

    "/i.js?#{encoded_terms}"
  end

  defp parse_image_results(body) do
    resp = Jason.decode!(body)
    {:ok, resp["results"]}
  end
end
