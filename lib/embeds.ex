defmodule Kirbot.Embeds do
  @moduledoc """
  Contains a consistent base for other embeds.
  """

  defmacro __using__(_opts) do
    quote do
      @teal_embed %Alchemy.Embed{color: 0x42EEF4}
      @red_embed %Alchemy.Embed{color: 0xbf3a46}
    end
  end
end
