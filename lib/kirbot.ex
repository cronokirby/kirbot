defmodule Kirbot do
  @moduledoc """
  Entry module to the bot application.
  """

  @token Application.get_env(:kirbot, :token)
  def hello do
    :world
  end
end
