### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache License, Version 2.0.
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule Xirsys.XTurn.Actions.HasRequestedTransport do
  @doc """
  Determines if a peer is assigned to a given transport type.
  Fixed to UDP as per TURN specification.
  """
  require Logger
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  @udp_proto <<17, 0, 0, 0>>

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    with true <- Map.has_key?(attrs, :requested_transport),
         @udp_proto <- Map.get(attrs, :requested_transport) do
      conn
    else
      false ->
        Logger.error(
          "Request transport not provided from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 400, "Bad Request")

      _ ->
        Logger.error(
          "Unsupported transport protocol requested from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 442, "Unsupported Transport Protocol")
    end
  end
end
