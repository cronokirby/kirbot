defmodule Kirbot do
  @moduledoc """
  Entry module to the bot application.
  """
  use Application
  alias Alchemy.Client

  @token Application.get_env(:kirbot, :token)

  def start(_type, _args) do
    run = Client.start(@token)
    load_modules()
    run
  end

  def load_modules do
    # modules will be added here later
  end
end
