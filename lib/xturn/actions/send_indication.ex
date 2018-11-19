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

defmodule Xirsys.XTurn.Actions.SendIndication do
  @doc """
  Sends data to a given peer
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  def process(%Conn{is_control: true}) do
    Logger.debug("cannot send indications on control connection")
    false
  end

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("send indication #{inspect(conn.decoded_message)}")
    tuple5 = Tuple5.to_map(Tuple5.create(conn, :_))

    with true <- Map.has_key?(attrs, :data) and Map.has_key?(attrs, :xor_peer_address),
         data <- Map.get(attrs, :data),
         peer_address = {_pip, _port} <- Map.get(attrs, :xor_peer_address),
         {:ok, [client, {_relay_ip, _relay_port}, socket, permission_cache]} <-
           Store.lookup(tuple5) do
      Logger.debug("sending indication to peer")
      AllocateClient.send_indication(client, peer_address, data, socket, permission_cache)
      conn
    else
      {:error, _} ->
        Logger.debug("client does not exist #{inspect(tuple5)} (send indication)")
        false

      _ ->
        Logger.debug("Required attributes not found during send indication")
        false
    end
  end
end
