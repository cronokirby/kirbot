defmodule Kirbot.HTTPUtil do
  @moduledoc """
  Just a few small common functions.
  """

  def get!(url) do
    HTTPoison.get!(url).body
    |> Poison.decode!
  end
end
