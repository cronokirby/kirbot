defmodule Kirbot.Mixfile do
  use Mix.Project

  def project do
    [app: :kirbot,
     version: "2.0.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [mod: {Kirbot, []}]
  end

  defp deps do
    [{:alchemy, git: "https://github.com/cronokirby/alchemy.git"}]
  end
end
