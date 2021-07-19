defmodule Xirsys.XTurn.Mixfile do
  use Mix.Project

  @version "0.1.3"

  def project do
    [
      app: :xturn,
      name: "xturn",
      version: @version,
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Xirsys XTurn TURN Server.",
      source_url: "https://github.com/xirsys/xturn",
      homepage_url: "https://xturn.me",
      package: package(),
      docs: [
        extras: ["README.md", "LICENSE.md"],
        main: "readme"
      ],
      escript: [main_module: Xirsys.XTurn],
      releases: [
        xturn: [
          version: @version,
          include_executables_for: [:unix],
          steps: [:assemble, :tar],
          applications: [
            xturn: :permanent,
            xturn_sockets: :permanent
          ]
        ]
      ]
    ]
  end

  def application do
    [
      applications: [:sasl, :logger, :ssl, :xmerl, :exts, :xturn_sockets],
      extra_applications: [:crypto],
      registered: [Xirsys.XTurn.Server],
      mod: {Xirsys.XTurn, []},
      logger: [compile_time_purge_level: :debug],
      env: [
        node_name: "xturn",
        node_host: "localhost",
        cookie: :IAMACOOKIEMONSTER
      ]
    ]
  end

  defp deps do
    [
      {:xturn_sockets, "~> 1.0.0"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:exts, "~> 0.3.4"}
    ]
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "docs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["Jahred Love <me@jah.red>"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/xirsys/xturn"}
    }
  end
end
