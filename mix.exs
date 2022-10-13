defmodule XTurn.MixProject do
  use Mix.Project

  def project do
    [
      app: :xturn,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:sasl, :logger, :ssl, :xmerl, :ranch, :socket],
      extra_applications: [:crypto],
      registered: [XTurn.Server],
      mod: {XTurn, []},
      logger: [compile_time_purge_level: :debug],
      env: [
        node_name: "xturn",
        node_host: "localhost",
        cookie: :IAMACOOKIEMONSTER
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:ranch, "~> 2.1"},
      {:socket, github: "Lazarus404/elixir-socket"}
    ]
  end
end
