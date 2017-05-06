defmodule Kirbot.Permissions.Store do
  @moduledoc """
  This serves as a simple K/V store, using DETS, to keep track
  of permission settings in different servers.
  A genserver is used to wrap around the table in order
  to ensure clean creation and deletion.
  """
  use GenServer
  alias Alchemy.Guild.Role

  def start_link(filename \\ :permissions) do
    GenServer.start_link(__MODULE__, {:file, filename}, name: __MODULE__)
  end

  def init({:file, filename}) do
    :dets.open_file(filename, [])
  end

  def terminate(_reason, table) do
    :dets.close(table)
    :normal
  end

  def get_info(guild) do
    GenServer.call(__MODULE__, {:get_info, guild})
  end

  def register(guild) do
    GenServer.call(__MODULE__, {:register, guild})
  end

  def remove(guild) do
    GenServer.call(__MODULE__, {:remove, guild})
  end

  def set_permission_level(guild, level, %Role{} = role) do
    GenServer.call(__MODULE__, {:set_perms, guild, level, role})
  end

  defp raw_info(table, guild) do
    case :dets.lookup(table, guild) do
      [] -> {:error, :no_guild}
      [{_, info}] -> {:ok, info}
    end
  end

  def handle_call({:get_info, guild}, _from, table) do
    {:reply, raw_info(table, guild), table}
  end

  def handle_call({:register, guild}, _from, table) do
    rank = %{rank: 0, name: "@everyone"}
    info = %{1 => rank, 2 => rank, 3 => rank}
    :dets.insert_new(table, {guild, info})
    {:reply, :ok, table}
  end

  def handle_call({:remove, guild}, _from, table) do
    :dets.delete(table, guild)
    {:reply, :ok, table}
  end

  defp new_ranks(range, op) do

  end

  def handle_call({:set_perms, guild, level, role}, _from, table) do
    {:ok, info} = raw_info(table, guild)
    rank_info = %{rank: role.position, name: role.name}
    new_ranks = fn range, op ->
      for x <- range, op.(info[x].rank, role.position), into: %{} do
        {x, rank_info}
      end
    end
    new =
      info
      |> put_in([level], rank_info)
      |> Map.merge(new_ranks.(level+1..3, &</2))
      |> Map.merge(new_ranks.(if level == 1 do [] else 1..level-1 end, &>/2))
    :dets.insert(table, {guild, new})
    {:reply, :ok, table}
  end
end
