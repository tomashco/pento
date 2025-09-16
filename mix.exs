defmodule Pento.MixProject do
  use Mix.Project

  def project do
    [
      app: :pento,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Pento.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:mail, ">= 0.0.0"},
      {:hackney, "~> 1.20"},
      {:gen_smtp, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:membrane_core, "~> 1.2.4"},
      {:membrane_ffmpeg_swscale_plugin, "~> 0.16.2"},
      {:membrane_ffmpeg_swresample_plugin, "~> 0.20.2"},
      {:membrane_transcoder_plugin, "~> 0.3.2"},
      {:membrane_webrtc_plugin, "~> 0.25.3"},
      {:membrane_opus_plugin, "~> 0.20.4"},
      {:membrane_raw_audio_parser_plugin, "~> 0.4.0"},
      {:membrane_realtimer_plugin, "~> 0.10.0"},
      {:membrane_portaudio_plugin, "~> 0.19.2"},
      {:membrane_mp3_mad_plugin, "~> 0.18.3"},
      {:membrane_mp3_lame_plugin, "~> 0.18.2"},
      {:membrane_file_plugin, "~> 0.17.0"},
      {:deepgram, "~> 0.1"},
      {:websockex, "~> 0.4.3"},
      {:nx, "== 0.10.0"},
      {:ortex, "== 0.1.9"},
      {:vix, "~> 0.33.0"},
      {:image, "~> 0.59.0"},
      {:evision, "~> 0.2.11"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind pento", "esbuild pento"],
      "assets.deploy": [
        "tailwind pento --minify",
        "esbuild pento --minify",
        "phx.digest"
      ]
    ]
  end
end
