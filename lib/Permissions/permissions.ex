defmodule Kirbot.Permissions do
  @moduledoc """
  A set of macros for defining commands restricted by certain permissions.
  """
  alias Kirbot.Permissions.Store
  use Kirbot.Embeds

  defmacro __using__(_opts) do
    quote do
      use Alchemy.Cogs
      use Kirbot.Embeds
      alias Kirbot.Permissions
      import Permissions
    end
  end

  defmacro restrict(level, do: body) do
    quote do
      with {:ok, guild} <- Alchemy.Cogs.guild(),
           {:ok, member} <- Alchemy.Cogs.member(),
           {:ok, has_perms} <- Kirbot.Permissions.Store.check_permissions(
             guild, unquote(level), member
           )
      do
        if has_perms do
          unquote(body)
        else
          Kirbot.Permissions.bad_permission_embed(guild, unquote(level))
          |> Alchemy.Embed.send
        end
      end
    end
  end

  def bad_permission_embed(guild, level) do
    required_role = Store.get_info(guild.id)[level].name
    @red_embed
    |> description("""
      Woops, you don't have permission to use #{level} commands in \
      #{guild.name}.
      You must be of rank #{required_role} or higher to access those commands.
      For more info, use `!permissions list`.
      """)
  end
end
