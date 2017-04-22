defmodule Kirbot.Speedrun.Commands do
  @moduledoc """
  The commands to interact with the speedrun api.
  """
  use Alchemy.Cogs
  use Kirbot.Embeds
  alias Alchemy.Embed
  import Embed
  alias Kirbot.Speedrun.API

  Cogs.set_parser(:search, &List.wrap/1)
  Cogs.def search(game) do
    case API.fetch_abbreviation(game) do
      {:ok, abb} ->
        @teal_embed
        |> description("The abbreviation for **#{game}** is **#{abb}**.")
      {:error, :invalid_game} ->
        @red_embed
        |> description("I couldn't find this game: `game`!")
    end
    |> Embed.send
  end
end
