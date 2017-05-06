defmodule Kirbot.Permissions.Commands do
  @moduledoc """
  The set of commands for interacting with the permission store.
  """
  use Kirbot.Permissions

  Cogs.group("permissions")

  Cogs.def bar do
    Cogs.guild_id() |> IO.inspect
  end

  Cogs.def foo do
    restrict 1 do
      f = "foo"
      Cogs.say f
    end
  end
end
