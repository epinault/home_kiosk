defmodule DashboardNerves.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  @all_targets [:rpi3]

  @app :dashboard_nerves

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.6",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.target() != :host,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DashboardNerves.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.5", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.4"},
      {:webengine_kiosk, "~> 0.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_init_gadget, "~> 0.4", targets: @all_targets},
      {:nerves_network, "0.3.7", targets: @all_targets},
      # {:nerves_system_br, "1.4.5"},
      {:nerves_time, "~> 0.2", targets: @all_targets},

      # Dependencies for specific targets
      # {:nerves_system_rpi3, "~> 1.5", runtime: false, targets: :rpi3},
      {:dashboard_web, path: "../dashboard_web", targets: :rpi3},
      {:kiosk_system_rpi3, "~> 1.8", runtime: false, targets: :rpi3}
      # {:nerves_toolchain_arm_unknown_linux_gnueabihf, "~> 1.3.1", nerves: [compile: true]}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
