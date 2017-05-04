defmodule Kirbot.Twitch.Commands do
  @moduledoc """
  A module providing commands related directly to the twitch API.

  These commands don't have the context of a particular server.
  """
  use Alchemy.Cogs
  use Kirbot.Embeds
  alias Kirbot.Twitch.API

  Cogs.def streaminfo(name) do
    with {:ok, %{online: true} = info} <- API.stream_info(name)
    do
      @teal_embed
      |> author(name: info.display_name, url: info.url)
      |> thumbnail(info.logo)
      |> field("Game:", info.game)
      |> field("Status:", info.status)
      |> field("Uptime:", info.uptime, inline: true)
      |> field("Viewers:", info.viewers, inline: true)
      |> field("Preview:", "\u200b")
      |> image(info.preview)
    else
      {:ok, %{online: false}} ->
        @red_embed
        |> description("`#{name}` isn't live at the moment.")
      {:error, :no_such_stream} ->
        @red_embed
        |> description("`#{name}` doesn't seem to have a channel on twitch")
    end
    |> Embed.send
  end
end
