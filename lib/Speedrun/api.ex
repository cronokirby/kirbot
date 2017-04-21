defmodule Kirbot.Speedrun.API do
  @moduledoc """
  Acts as an interface to the speedrun.com api.
  """

  @root "http://www.speedrun.com/api/v1/"

  defp get!(url) do
    resp = HTTPoison.get!(url)
    case resp do
      %{status_code: 302} ->
        {_, location} = Enum.find(resp.headers, fn
          {"Location", _} -> true
          _ -> false
        end)
        get!("http://www.speedrun.com" <> location)
      _ ->
        Poison.decode! resp.body
    end
  end
  def fetch_name(user_url) do
    # these only get called from commands anyways, crashing is fine
    get!(user_url)["data"]["names"]["international"]
  end

  def fetch_id(name) do
    url = @root <> "games?name=" <> URI.encode(name)
    case get!(url)["data"] do
      [] -> {:error, "Invalid game name"}
      [x|_] -> {:ok, x["id"]}
    end
  end

  def fetch_abbreviation(name) do
    url = @root <> "games?name=" <> URI.encode(name)
    case get!(url)["data"] do
      [] -> {:error, "Invalid game name"}
      [x|_] -> {:ok, x["abbreviation"]}
    end
  end

  def fetch_categories(game) do
    data = get!(@root <> "games/" <> game <> "/categories")["data"]
    Task.async_stream(data, fn category ->
      variable_data = get!(Enum.at(category["links"], 2)["uri"])["data"]
      case variable_data do
        [] ->
          [{category["name"], {Enum.at(category["links"], 5)["uri"]}}]
        [variables|_]  ->
          variables
          |> get_in(["values", "values"])
          |> Enum.map(fn {k, v} ->
            name = category["name"] <> " - " <> v["label"]
            link = Enum.at(category["links"], 5)["uri"]
            {name, {link, k}}
          end)
      end
    end)
    |> Stream.map(fn {:ok, v} -> v end)
    |> Stream.concat
    |> Enum.into(%{})
  end
end
