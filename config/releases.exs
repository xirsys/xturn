import Config

config :logger,
  level: :info

realm_name = System.fetch_env!("REALM")

server_ip =
  case System.fetch_env("SERVER_IP") do
    :error ->
      nil

    {:ok, server_ip} ->
      server_ip |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
  end

server_crt = System.fetch_env!("SERVER_CRT")
server_key = System.fetch_env!("SERVER_KEY")

config :xturn,
  authentication: %{required: true, username: "guest", credential: "guest"},
  permissions: %{required: true},
  realm: realm_name,
  nonce: "d24ed7ae2db4c48f",
  listen: [
    {:udp, '0.0.0.0', 80},
    {:tcp, '0.0.0.0', 80},
    {:udp, '0.0.0.0', 3478},
    {:tcp, '0.0.0.0', 3478},
    {:udp, '0.0.0.0', 443, :secure},
    {:tcp, '0.0.0.0', 443, :secure},
    {:udp, '0.0.0.0', 5349, :secure},
    {:tcp, '0.0.0.0', 5349, :secure}
  ],
  use_fingerprint: true,
  server_id: realm_name,
  server_ip: server_ip,
  server_local_ip: {0, 0, 0, 0},
  certs: [
    certfile: server_crt |> String.to_charlist(),
    keyfile: server_key |> String.to_charlist()
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
