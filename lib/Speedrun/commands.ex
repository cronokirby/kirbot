defmodule Kirbot.Speedrun.Commands do
  @moduledoc """
  The commands to interact with the speedrun api.
  """
  use Alchemy.Cogs
  use Kirbot.Embeds
  alias Alchemy.Embed
  import Embed
  alias Kirbot.Speedrun.API


  Cogs.set_parser(:search, &List.wrap/1)
  Cogs.def search(game) do
    case API.fetch_abbreviation(game) do
      {:ok, abb} ->
        @teal_embed
        |> description("The abbreviation for **#{game}** is **#{abb}**")
      {:error, :invalid_game} ->
        @red_embed
        |> description("I couldn't find this game: `#{game}`")
    end
    |> Embed.send
  end


  Cogs.def categories(dashed) do
    id = if String.contains?(dashed, "-") do
      API.fetch_id(String.replace(dashed, "-", " "))
    else
      {:ok, dashed}
    end
    with {:ok, name} <- id,
         {:ok, cats} <- API.fetch_categories(name)
    do
      cat_names =
        cats
        |> Stream.map(fn {k, _v} -> "`#{k}`" end)
        |> Enum.join("\n")
      @teal_embed
      |> description("Here's a list of valid categories for "
                     <> "**#{dashed}**:\n"
                     <> cat_names)
    else
      {:error, :invalid_game} ->
        @red_embed
        |> description("I couldn't find this game: `#{dashed}`")
    end
    |> Embed.send
  end


  Cogs.set_parser(:wr, &String.split(&1, " ", parts: 2))
  Cogs.def wr(dashed, cat) do
    time(message, "1", dashed, cat)
  end


  Cogs.set_parser(:time, &String.split(&1, " ", parts: 3))
  Cogs.def time(rank, dashed, cat) do
    id = if String.contains?(dashed, "-") do
      API.fetch_id(String.replace(dashed, "-", " "))
    else
      {:ok, dashed}
    end
    with {:ok, id} <- id,
         {:ok, cats} <- API.fetch_categories(id),
         {:rank, {rank, _}} <- {:rank, Integer.parse(rank)}
    do
      cat_info(dashed, cats, id, cat, rank)
    else
      {:error, :invalid_game} ->
        @red_embed
        |> description("I couldn't find this game: `#{dashed}`")
    end
    |> Embed.send
  end

  def cat_info(dashed, cats, id, "All", rank) do
    cats
    |> Map.keys
    |> Task.async_stream(fn cat ->
      {cat, API.fetch_time(id, cat, rank - 1)}
    end)
    |> Stream.map(fn
      {:ok, {cat, {:ok, r}}} -> {cat, r}
      {:ok, {cat, {:error, why}}} -> {cat, why}
    end)
    |> Stream.map(fn
      {c, {:bad_rank, count}} ->
        {c, "*only has #{count} runs*"}
      {c, r} ->
        {c, "**#{r.time}** by **#{r.name}**"}
    end)
    |> Enum.reduce(@teal_embed, fn {c, f}, embed ->
      field(embed, c, f)
    end)
    |> description("Here are all the #{format_rank(rank)}s for #{dashed}")
  end
  def cat_info(dashed, cats, id, cat, rank) do
    with true <- Map.has_key?(cats, cat),
         {:ok, run} <- API.fetch_time(id, cat, rank - 1)
    do
      {:ok, run} = API.fetch_time(id, cat, rank - 1)
      m = "The #{format_rank(rank)} is **#{run.time}** "
       <> "by **#{run.name}**\n<#{run.vod}>"
      @teal_embed
      |> description(m)
    else
      false ->
        m = "**#{cat}** doesn't seem to be a valid category for "
         <> "**#{dashed}**\nTry `!categories game` for a full list"
        @red_embed
        |> description(m)
      {:error, {:bad_rank, runcount}} ->
        @red_embed
        |> description("**#{cat}** only has **#{runcount}** runs")
    end
  end

  defp format_rank(1), do: "**WR**"
  defp format_rank(2), do: "**2nd** place time"
  defp format_rank(3), do: "**3rd** place time"
  defp format_rank(n) when n in 4..19, do: "**#{n}th** place time"
  defp format_rank(n) do
    ext = case div(n, 10) do
      1 -> "st"
      2 -> "nd"
      3 -> "rd"
      _n -> "th"
    end
    "**#{n}#{ext}** place time"
  end
end
