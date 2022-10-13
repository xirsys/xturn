import Config

config :logger,
  level: :info

bind_ip = '192.168.1.194'

config :xturn,
  listen: [
    # {:udp, bind_ip, 80},
    # {:tcp, bind_ip, 80},
    {:udp, bind_ip, 3478},
    {:tcp, bind_ip, 3478}
    # {:udp, bind_ip, 443, :secure},
    # {:tcp, bind_ip, 443, :secure},
    # {:udp, bind_ip, 5349, :secure},
    # {:tcp, bind_ip, 5349, :secure}
  ],
  server_ip: {192, 168, 1, 194},
  turn_key: "<secret_key>",
  nonce: "12345678",
  realm: "xirsys.com",
  pipes: %{
    allocate: [
      XTurn.Actions.Authenticates,
      XTurn.Actions.HasRequestedTransport,
      XTurn.Actions.NotAllocationExists,
      XTurn.Actions.Allocate
    ],
    createperm: [
      XTurn.Actions.Authenticates,
      XTurn.Actions.CreatePerm
    ],
    send: [
      XTurn.Actions.SendIndication
    ],
    channelbind: [
      XTurn.Actions.Authenticates,
      XTurn.Actions.ChannelBind
    ]
    # refresh: [
    #   XTurn.Actions.Authenticates,
    #   XTurn.Actions.Refresh
    # ]
  }

if Mix.env() == "dev" do
  config :peerage,
    via: Peerage.Via.List,
    node_list: [:"xturn@0.0.0.0"],
    log_results: false
end
