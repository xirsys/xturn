defmodule Xirsys.XTurn.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :xturn,
      version: "0.1.0",
      elixir: ">= 1.4.2",
      name: "xturn",
      source_url: "https://github.com/xirsys/xturn",
      escript: [main_module: Xirsys.XTurn],
      deps: deps()
    ]
  end

  def application() do
    [
      applications: [:crypto, :sasl, :logger, :ssl, :xmerl, :exts, :maru],
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
      {:xmedialib, git: "https://github.com/xirsys/xmedialib"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.18.3"},
      {:exts, "~> 0.3.4"},
      {:poolboy, "~> 1.5", override: true},
      {:maru, "~> 0.13"},
      {:jason, "~> 1.0"},
      {:cowboy, "~> 2.3"}
    ]
  end
end
