defmodule DashboardWeb.PageView do
  use DashboardWeb, :view

  def date_to_dayname(datestr) do
    with {:ok, date} <- Calendar.Date.Parse.iso8601(datestr),
         {:ok, day} <- Calendar.Strftime.strftime(date, "%A") do
      day
    else
      _ ->
        "N/A"
    end
  end
end
