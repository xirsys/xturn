defmodule Xirsys.XTurn.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :xturn,
      version: "0.1.0",
      elixir: ">= 1.6.6",
      name: "xturn",
      source_url: "https://github.com/xirsys/xturn",
      escript: [main_module: Xirsys.XTurn],
      deps: deps()
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
      {:xmedialib,
       git: "https://github.com/xirsys/xmedialib",
       ref: "dbbc2d91a9422c0e677ca8a71029383f847e7b2d",
       override: true},
      {:xturn_sockets,
       git: "https://github.com/xirsys/xturn-sockets",
       ref: "fbb2a1cd17c7d895a91c855c3d062e09ecf01b32",
       override: true},
      {:xturn_cache, git: "https://github.com/xirsys/xturn-cache"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.18.3"},
      {:exts, "~> 0.3.4"}
    ]
  end
end
