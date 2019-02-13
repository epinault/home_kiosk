defmodule DashboardWeb.Weather do
  import Calendar.Strftime

  def render(lat, long) do
    case Darkskyx.forecast(lat, long) do
      {:ok, data} ->
        to_html(data)

      {:error, error} ->
        %{error: error}
    end
  end

  def to_html(data) do
    Phoenix.View.render_to_string(
      DashboardWebWeb.PageView,
      "weather.html",
      data: convert_data(data["daily"]["data"])
    )
  end

  def convert_data(daily_data) do
    {:ok, current_time} = Calendar.DateTime.now("America/Los_Angeles")

    daily_data
    |> Enum.take(7)
    |> Enum.with_index()
    |> Enum.map(fn {day, index} ->
      {:ok, d} = Calendar.DateTime.add(current_time, index * 86400)
      {:ok, short_name} = d |> strftime("%a")

      %{
        "day" => short_name,
        "icon" => day["icon"],
        "low" => Kernel.round(day["temperatureLow"]),
        "high" => Kernel.round(day["temperatureHigh"])
      }
    end)
  end
end
