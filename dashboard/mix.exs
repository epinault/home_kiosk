defmodule Dashboard.MixProject do
  use Mix.Project

  def project do
    [
      app: :dashboard,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Dashboard.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:calendar, "~> 1.0.0"},
      {:darkskyx, "~> 1.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.15.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
