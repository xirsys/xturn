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

defmodule Xirsys.XTurn.Actions.NotAllocationExists do
  @doc """
  Checks if the current 5-tuple has previously been used. If so,
  then this is a duplicate allocation request and can be safely
  ignored.
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.Sockets.{Socket, Conn}
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    tup5 = [
      {:ca, conn.client_ip},
      {:cp, conn.client_port},
      {:sa, Socket.server_ip()},
      {:sp, conn.server_port},
      {:proto, Map.get(attrs, :requested_transport)}
    ]

    with false <- Store.exists(tup5) do
      conn
    else
      _ ->
        Logger.info(
          "Allocation already exists from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        # Conn.response(conn, 437, "Allocation Mismatch")
        {:ok, [_client, {_ip, port}, _, _]} = Store.lookup(tup5)
        Logger.debug("#{inspect(port)}")

        nattrs = [
          # reservation_token: <<0::64>>,
          xor_mapped_address: {conn.client_ip, conn.client_port},
          xor_relayed_address: {Socket.server_ip(), port},
          lifetime: <<600::32>>
        ]

        Logger.debug("integrity = #{conn.decoded_message.integrity}")
        Logger.debug("Allocated")
        Conn.response(conn, :success, nattrs)
        Conn.halt(conn)
    end
  end
end
