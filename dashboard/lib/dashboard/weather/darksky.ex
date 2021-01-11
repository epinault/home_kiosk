defmodule Dashboard.Weather.Darksky do
  @moduledoc """
  A Darksky implementation retriever to get the daily
  and hourly weather
  """
  @behaviour Dashboard.Weather.Retriever
  import Calendar.Strftime

  def retrieve_data(lat, long) do
    case Darkskyx.forecast(lat, long) do
      {:ok, data, _} ->
        {:ok, convert_data(data)}

      {:error, error, status_code} ->
        {:error, error}
    end
  end

  def convert_data(data) do
    {:ok, current_time} = Calendar.DateTime.now("America/Los_Angeles")

    daily_data = data["daily"]["data"]

    daily_summary =
      daily_data
      |> Enum.take(7)
      |> Enum.with_index()
      |> Enum.map(fn {day, index} ->
        {:ok, d} = Calendar.DateTime.add(current_time, index * 86_400)
        {:ok, short_name} = d |> strftime("%a")

        %{
          "day" => short_name,
          "icon" => day["icon"],
          "low" => Kernel.round(day["temperatureLow"]),
          "high" => Kernel.round(day["temperatureHigh"]),
          "summary" => day["summary"]
        }
      end)

    summary = Map.put(%{}, :daily, daily_summary)

    hourly_data = data["hourly"]["data"]

    hourly_summary =
      hourly_data
      |> Enum.take(8)
      |> Enum.map(fn hour ->
        {:ok, date} =
          Calendar.DateTime.Parse.unix!(hour["time"])
          |> Calendar.DateTime.shift_zone("America/Los_Angeles")

        {:ok, hour_formatted} = Calendar.Strftime.strftime(date, "%l%p")

        %{
          "hour" => hour_formatted,
          "temperature" => hour["temperature"],
          "summary" => hour["summary"]
        }
      end)

    summary = Map.put(summary, :hourly, hourly_summary)
    summary
  end
end
