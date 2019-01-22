use Mix.Config

config :logger,
  level: :debug,
  compile_time_purge_level: :debug

config :xturn,
  authentication: %{required: false},
  permissions: %{required: true}, # for some reason, turnutils_uclient doesn't set permissions for DTLS
  realm: "xturn.com",
  listen: [
    {:udp, '0.0.0.0', 3478},
    {:tcp, '0.0.0.0', 3478},
    {:udp, '0.0.0.0', 5349, :secure},
    {:tcp, '0.0.0.0', 5349, :secure}
  ],
  server_type: "turn",
  server_id: "xturn.com",
  server_ip: {127, 0, 0, 1},
  server_local_ip: {0, 0, 0, 0},
  certs: [
    {:certfile, "certs/server.crt"},
    {:keyfile, "certs/server.key"}
  ],
  pipes: %{
    allocate: [
      Xirsys.XTurn.Actions.HasRequestedTransport,
      Xirsys.XTurn.Actions.NotAllocationExists,
      Xirsys.XTurn.Actions.Authenticates,
      Xirsys.XTurn.Actions.Allocate
    ],
    refresh: [
      Xirsys.XTurn.Actions.Authenticates,
      Xirsys.XTurn.Actions.Refresh
    ],
    channelbind: [
      Xirsys.XTurn.Actions.Authenticates,
      Xirsys.XTurn.Actions.ChannelBind
    ],
    createperm: [
      Xirsys.XTurn.Actions.Authenticates,
      Xirsys.XTurn.Actions.CreatePerm
    ],
    send: [
      Xirsys.XTurn.Actions.SendIndication
    ],
    channeldata: [
      Xirsys.XTurn.Actions.ChannelData
    ]
  }

config :maru, Xirsys.API, http: [port: 8880]
