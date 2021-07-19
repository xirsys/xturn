import Config

config :logger,
  level: :info

realm_name = System.fetch_env!("REALM")
app_host_ip = System.fetch_env!("APP_HOST_IP")
server_ip = System.fetch_env!("SERVER_IP")
server_local_ip = System.fetch_env!("SERVER_LOCAL_IP")

config :xturn,
  authentication: %{required: false, username: "guest", credential: "guest"},
  permissions: %{required: false},
  realm: realm_name,
  listen: [
    # {:udp, String.to_charlist(app_host_ip), 80},
    # {:tcp, String.to_charlist(app_host_ip), 80},
    {:udp, String.to_charlist(app_host_ip), 3478},
    {:tcp, String.to_charlist(app_host_ip), 3478},
    # {:udp, String.to_charlist(app_host_ip), 443, :secure},
    # {:tcp, String.to_charlist(app_host_ip), 443, :secure},
    {:udp, String.to_charlist(app_host_ip), 5349, :secure},
    {:tcp, String.to_charlist(app_host_ip), 5349, :secure}
  ],
  server_id: realm_name,
  server_ip: server_ip |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple(),
  server_local_ip: server_local_ip |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple(),
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