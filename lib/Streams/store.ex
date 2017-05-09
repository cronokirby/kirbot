defmodule Kirbot.Streams.Store do
  @moduledoc """
  This serves as a simple K/V store, keeping track of the stream
  alert settings in various guilds, as well as keeping track of a total
  set of streams to keep live info of.
  """
  use GenServer
  alias Kirbot.Twitch.API

  def start_link(filename \\ :streams) do
    GenServer.start_link(__MODULE__, {:file, filename}, name: __MODULE__)
  end

  def init({:file, filename}) do
    :dets.open_file(filename, [])
  end

  def terminate(_reason, table) do
    :dets.close(table)
    :normal
  end

  def register(guild_id) do
    GenServer.call(__MODULE__, {:register, guild_id})
  end

  def remove(guild_id) do
    GenServer.call(__MODULE__, {:remove, guild_id})
  end

  def enable(guild_id) do
    GenServer.call(__MODULE__, {:edit_enabled, &MapSet.put/2, guild_id})
  end

  def disable(guild_id) do
    GenServer.call(__MODULE__, {:edit_enabled, &MapSet.delete/2, guild_id})
  end

  def add_stream(guild_id, name) do
    case API.find_stream(name) do
      {:exists, _} ->
        {:ok, GenServer.call(__MODULE__, {:add_stream, guild_id, name})}
      :no_such_stream ->
        {:error, :no_such_stream}
    end
  end

  def remove_stream(guild_id, name) do
    GenServer.call(__MODULE__, {:remove_stream, guild_id, name})
  end

  def toggle_filters(guild_id, toggle) do
    GenServer.call(__MODULE__, {:filters, guild_id, toggle})
  end

  def enabled?(guild_id) do
    GenServer.call(__MODULE__, {:enabled?, guild_id})
  end

  def add_filter(guild_id, game) do
    with {:ok, game} <- API.find_game(game) do
      GenServer.call(__MODULE__, {:add_filter, guild_id, game})
    end
  end

  def remove_filter(guild_id, game) do
    GenServer.call(__MODULE__, {:remove_filter, guild_id, game})
  end

  def get_filters(guild_id) do
    GenServer.call(__MODULE__, {:get_filters, guild_id})
  end

  defp raw_info(table, guild_id) do
    case :dets.lookup(table, guild_id) do
      [] ->
        {:error, :no_guild}
      [{_, info}] ->
        {:ok, info}
    end
  end

  # handles creation of the set
  defp maybe_set(table, key) do
    case :dets.lookup(table, key) do
      [] ->
        set = MapSet.new()
        :dets.insert(table, {key, set})
        set
      [{_, set}] ->
        set
    end
  end

  defp get_enabled(table) do
    maybe_set(table, :enabled)
  end

  defp get_streams(table) do
    maybe_set(table, :streams)
  end

  def handle_call({:register, guild_id}, _from, table) do
    info = %{streamlist: MapSet.new(),
             live_streams: [],
             channel: nil,
             filters: %{enabled: false, set: MapSet.new()}}
    :dets.insert_new(table, {guild_id, info})
    {:reply, :ok, table}
  end

  def handle_call({:remove, guild_id}, _from, table) do
    :dets.delete(table, guild_id)
    {:reply, :ok, table}
  end

  def handle_call({:edit_enabled, op, guild_id}, _from, table) do
    set = get_enabled(table) |> op.(guild_id)
    :dets.insert(table, {:enabled, set})
    {:reply, :ok, table}
  end

  def handle_call({:add_stream, guild_id, name}, _from, table) do
    new = get_streams(table) |> Map.update(name, 1, & &1 + 1)
    :dets.insert(table, {:streams, new})
    {:reply, :ok, table}
  end

  def handle_call({:remove_stream, guild_id, name}, _from, table) do
    new = get_streams(table) |> Map.get_and_update(name, fn
      n when n > 1 -> n - 1
      _ -> :pop
    end)
    :dets.insert(table, {:streams, new})
    {:reply, :ok, table}
  end

  def handle_call({:filters, guild_id, toggle}, _from, table) do
    {:ok, info} = raw_info(table, guild_id)
    new = put_in(info.filters.enabled, toggle)
    :dets.insert(table, {guild_id, new})
    {:reply, :ok, table}
  end

  def handle_call({:enabled?, guild_id}, _from, table) do
    {:ok, info} = raw_info(table, guild_id)
    {:reply, info.filters.enabled, table}
  end

  # must be checked to be an actual game before hand
  def handle_call({:add_filter, guild_id, game_name}, _from, table) do
    {:ok, info} = raw_info(table, guild_id)
    new = update_in(info.filters.set, &MapSet.put(&1, game_name))
    {:reply, game_name, table}
  end

  def handle_call({:remove_filter, guild_id, game_name}, _from, table) do
    {:ok, info} = raw_info(table, guild_id)
    new = update_in(info.filters.set, &MapSet.delete(&1, game_name))
    {:reply, :ok, table}
  end

  def handle_call({:get_filters, guild_id}, _from, table) do
    {:ok, info} = raw_info(table, guild_id)
    {:reply, info.filters.set, table}
  end
end
