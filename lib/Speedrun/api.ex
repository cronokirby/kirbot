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
        Poison.decode!(resp.body)
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
      [] -> {:error, :invalid_game}
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

  def fetch_time(game, category, rank) do
    runs = case fetch_categories(game)[category] do
      nil ->
        {:error, :no_cat}
      {url} ->
        {:ok, get!(url)["data"]["runs"]}
      {url, variable} ->
        {:ok, Enum.filter(get!(url)["data"]["runs"], fn run ->
          variable in Map.values(run["run"]["values"])
        end)}
    end
    with {:ok, runs} <- runs do
      runcount = length(runs)
      unless rank in -runcount..runcount + 1 do
        {:error, :bad_rank}
      else
        run = runs |> Enum.at(rank) |> run_info
      end
    end
  end

  defp run_info(run) do
    time = run["run"]["times"]["primary_t"]
    player =
    name = case Enum.at(run["run"]["players"], 0) do
      %{"rel" => "user", "uri" => u} ->
        fetch_name(u)
      %{"name" => n} ->
        n
    end
    vod = case run["run"]["videos"] do
      nil ->
        :none
      some ->
        Enum.at(some["links"], 0)["uri"]
    end
    %{name: name, time: time, vod: vod}
  end
end
