defmodule Kirbot.Permissions.Commands do
  @moduledoc """
  The set of commands for interacting with the permission store.
  """
  use Kirbot.Permissions
  alias Kirbot.Permissions.Store

  Cogs.group("permissions")

  @permission_level 3

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

  Cogs.set_parser(:set, &String.split(&1, " ", parts: 2))
  Cogs.def set(level, name) do
    restrict @permission_level do
      {:ok, guild} = Cogs.guild()
      with {:int, {i, _}} when i in 1..3 <- {:int, Integer.parse(level)},
           role when role != nil <- Enum.find(guild.roles, &(&1.name == name))
      do
        :ok = Store.set_permission_level(guild.id, i, role)
        @teal_embed
        |> description("Permission level `#{level}` is now set to " <>
                       "`#{name}` or higher.\nUse `!permissions list` " <>
                       "for the role hierarchy.")
      else
        nil ->
          @red_embed
          |> description("`#{name}` doesn't seem to be a valid role in " <>
                         "**#{guild.name}**.\nFor more info, use " <>
                         "`!permissions info`")
        {:int, _} ->
          @red_embed
          |> description("The permission level must be a number " <>
                         "between 1 and 3.\nFor more info, use " <>
                         "`!permissions info`")
      end
      |> Embed.send
    end
  end
end
