defmodule Kirbot.Permissions.Commands do
  @moduledoc """
  The set of commands for interacting with the permission store.
  """
  use Kirbot.Permissions
  alias Kirbot.Permissions.Store

  Cogs.group("permissions")

  def hierarchise(roles) do
    roles
    |> Enum.sort_by(& &1.position)
    |> Enum.map(&{&1.position, &1.name})
  end

  Cogs.def list do
    with {:ok, guild} <- Cogs.guild(),
         {:ok, info} <- Store.get_info(guild.id)
    do
      hierarchy = hierarchise(guild.roles)
      [l1, l2, l3] = for x <- 1..3 do
        Enum.filter(hierarchy, fn {p, _} -> p >= info[x].rank end)
      end
      format = &Enum.map_join(&1, ", ", fn {_, n} -> "`#{n}`" end)
      @teal_embed
      |> description("Here's some info about the permissions " <>
                     "in **#{guild.name}**")
      |> field("Hierarchy:", format.(hierarchy))
      |> field("Level 1:", format.(l1))
      |> field("Level 2:", format.(l2))
      |> field("Level 3:", format.(l3))
      |> Embed.send
    end
  end
end
