defmodule Kirbot do
  @moduledoc """
  Entry module to the bot application.
  """
  use Application
  import Supervisor.Spec
  alias Alchemy.Client
  alias Kirbot.Permissions
  alias Kirbot.Streams

  @token Application.get_env(:kirbot, :token)

  def start(_type, _args) do
    children = [
      worker(Client, [@token, []]),
      worker(Permissions.Store, []),
      worker(Streams.Store, [])
    ]
    run = Supervisor.start_link(children, strategy: :one_for_one)
    load_modules()
    run
  end

  def load_modules do
    alias Kirbot.{Basic, Speedrun, Permissions}
    use Basic
    use Speedrun.Commands
    use Permissions.Commands
  end
end
