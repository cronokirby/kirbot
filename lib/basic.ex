defmodule Kirbot.Basic do
  @moduledoc """
  A set of miscellaneous commands.
  """
  use Alchemy.Cogs
  alias Alchemy.Embed
  alias Alchemy.User
  import Embed

  @teal 0x42EEF4

  Cogs.def test do
    %Embed{}
    |> description("#{message.author}, what is a *test* ? :whale2:")
    |> color(@teal)
    |> thumbnail("http://imgur.com/dU6KiDb.png")
    |> author(name: message.author.username,
              icon_url: User.avatar_url(message.author))
    |> Embed.send
  end
end
