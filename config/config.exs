use Mix.Config

config :logger,
  level: :info

config :xturn,
  authentication: %{required: true, username: "guest", credential: "guest"},
  # for some reason, turnutils_uclient doesn't set permissions for DTLS
  permissions: %{required: true},
  realm: "xturn.me",
  nonce: "d24ed7ae2db4c48f",
  listen: [
    # {:udp, '0.0.0.0', 80},
    # {:tcp, '0.0.0.0', 80},
    {:udp, '0.0.0.0', 3478},
    {:tcp, '0.0.0.0', 3478},
    # {:udp, '0.0.0.0', 443, :secure},
    # {:tcp, '0.0.0.0', 443, :secure},
    {:udp, '0.0.0.0', 5349, :secure},
    {:tcp, '0.0.0.0', 5349, :secure}
  ],
  use_fingerprint: true,
  server_type: "turn",
  server_id: "xturn.me",
  server_ip: {0,0,0,0},
  server_local_ip: {0,0,0,0},
  certs: [
    cacertfile: 'certs/xturn.ca.pem',
    certfile: 'certs/xturn.cert.pem',
    keyfile: 'certs/xturn.key.pem'
  ],
  client_hooks: [],
  peer_hooks: [],
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

if Mix.env() == "dev" do
  config :peerage,
    via: Peerage.Via.List,
    node_list: [:"xturn@0.0.0.0"],
    log_results: false
end
