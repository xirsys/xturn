defmodule Xirsys.XTurn.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :xturn,
      name: "xturn",
      version: "0.1.3",
      elixir: "~> 1.7",
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
      escript: [main_module: Xirsys.XTurn]
    ]
  end

  def application() do
    [
      applications: [:crypto, :sasl, :logger, :ssl, :xmerl, :exts],
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

  defp deps() do
    [
      {:xmedialib, "~> 0.1.2"},
      {:xturn_sockets, github: "xirsys/xturn-sockets"},
      {:xturn_cache, "~> 0.1.0"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:exts, "~> 0.3.4"}
    ]
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "docs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["Jahred Love"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/xirsys/xturn"}
    }
  end
end
