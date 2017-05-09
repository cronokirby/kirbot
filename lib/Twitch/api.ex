defmodule Kirbot.Twitch.API do
  @moduledoc """
  Provides functions for interfacing with the twitch API.
  """

  @root "https://api.twitch.tv/kraken/"

  @client_id Application.get_env(:kirbot, :twitch_client_id)

  def get!(url) do
    headers = [{"Content-Type", "application/json"},
               {"Client-ID", @client_id}]
    HTTPoison.get!(url, headers).body
    |> Poison.decode!
  end

  def find_stream(name) do
    case get!(@root <> "streams/#{name}") do
      %{"stream" => nil} -> {:exists, :offline}
      %{"stream" => _} -> {:exists, :online}
      _ -> :no_such_stream
    end
  end

  def find_game(name) do
    case @root <> "search/games?q=" <>
    String.replace(name, " ", "+") <> "&type=suggest"
    |> get!
    |> get_in(["games"])
    do
      [] -> {:error, :no_game}
      [%{"name" => name}|_] -> {:ok, name}
    end
  end

  def stream_info(name) do
    stream_link = "http://twitch.tv/#{name}"
    case get!(@root <> "streams/#{name}") do
      %{"stream" => nil} ->
        {:ok,
         %{online: false,
           url: stream_link}}
      %{"stream" => info} ->
        {:ok,
         %{uptime: info["created_at"],
           online: true,
           url: stream_link,
           game: info["game"],
           viewers: info["viewers"],
           preview: info["preview"]["medium"],
           display_name: info["channel"]["display_name"],
           status: info["channel"]["status"],
           logo: info["channel"]["logo"]}}
      _ ->
        {:error, :no_such_stream}
    end
  end
end
