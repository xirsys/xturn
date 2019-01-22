XTurn - Xirsys TURN Server in Elixir
=====

This is an implementation of a TURN server in Elixir (based on the xstun server project).  It was originally written in Erlang and ported in 2014 when we migrated our other code.  It's never been in production and, indeed, needs more work for that.  However, it's a great little personal project and fun to work with.  It works nicely with WebRTC.

Supported Features
===

- TCP, UDP, TLS and DTLS supported
- Full TURN RFC5766 support (except rotating nonce)
- Full STUN RFC3489 support
- Simple user / pass storage with Web API interface
- Channel Binding / Data IS supported!
- WebRTC Data Channels ARE supported!

Setup
===
Open the `config.exs` file in `config`.  All options are there.

Logging
---
Logging sloooooows the server down.  For production quality (faster than Google's), drop the Logging level to `:error` or `:info`.  Keeping at `:debug` is fine for development, but will provide a degragation of service.

    config :logger,
      level: :debug,
      compile_time_purge_level: :debug

Ports
---
The listening ports should be set, next.  Standard ports are already set, but it can oftimes be beneficial to open on 80 and 443, too.  Make sure to specify `:secure` on known secure ports, which will enable SSL.

    config :xturn,
      authentication: %{required: true},
      permissions: %{required: false},
      realm: "xirsys.com",
      listen: [
                {:udp, '0.0.0.0', 3478},
                {:tcp, '0.0.0.0', 3478},
                {:udp, '0.0.0.0', 5349, :secure},
                {:tcp, '0.0.0.0', 5349, :secure}
              ],
      server_type: "turn",
      server_id: "turn.myserver.com",
      server_ip: {127, 0, 0, 1},
      server_local_ip: {0, 0, 0, 0},
      certs: [
               {:certfile, "certs/server.crt"},
               {:keyfile, "certs/server.key"}
             ]

*authentication*: specifying required as `true` will prevent connections without a valid user and password in the user store

*permissions*: TURN usually requires a `create permissions` call.  Setting requireed to false will allow connections without permissions being set.

*server_ip*: this is the public IP of your server.  Not all server setups make this aware to the app, so it's necessary to set this manually (for now).

*server_local_ip*: this is the internal IP to bind sockets to.  Again, this may be temporary.  You still need to set the IP in the individual socket listeners, too.

Note that `server_type` is a Xirsys thing and can be ignored.

Maru
---

Maru is an Elixir HTTP server library.  This TURN server provide some lightweight API features for creating user credentials and viewing throughput stats.  This will improve with time (it's just for testing atm).

    config :maru, Xirsys.API,
      http: [port: 8880]

Change the port number to access the API from a different port.

Future Plans
===

- Create a rotating nonce
- Get a decent user credential store working with decent timeout capability (it's a little limited at the moment).
- Get RTP and RTCP working with a new MCU or SFU functionality
- Implement stream recording to file
- Implement third party streaming server connectivity
- Full support for IPv6
- TCP Allocations (connect command)

Changelog
===
19-11-2018 - Simplify Pipelines module, moving pipeline descriptors to the config file. Also added [Getting Started](getting-started.md) page, describing testing the server.

22-01-2019 - Updated to work with latest XMediaLib

30-10-2018 - Extract actions to module based pipeline

12-07-2018 - Externalised XMediaLib as a separate library

04-07-2018 - Aside from some cleanup, client calls were short-cicuited through direct passing of the client socket ref, rather than the GenServer pid

02-07-2018 - Get working with test.webrtc.org

26-06-2018 - Add DTLS support

21-09-2014 - Convert to Elixir

14-12-2013 - Initial working implementation in Erlang

Contact
===
For questions or suggestions, please email experts@xirsys.com

Copyright
===

Copyright (c) 2013 - 2018 Xirsys LLC

All rights reserved.

XTurn is licensed by Xirsys under the Apache License, Version 2.0. See LICENSE for the full license text.