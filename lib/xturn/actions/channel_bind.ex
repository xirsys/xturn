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

defmodule Xirsys.XTurn.Actions.ChannelBind do
  @doc """
  Channel binds a peer to a given client allocation
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Channels.Store, as: Channels
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("channelbinding #{inspect(conn.decoded_message)}")

    with true <- Map.has_key?(attrs, :channel_number) and Map.has_key?(attrs, :xor_peer_address),
         <<channel_number::16, _::16>> <- Map.get(attrs, :channel_number),
         peer_address = {_, _} <- Map.get(attrs, :xor_peer_address),
         tuple5 <- Tuple5.to_map(Tuple5.create(conn, :_)) do
      Logger.debug(
        "#{Channels.exists({channel_number, tuple5})}, #{Channels.exists({peer_address, tuple5})} = #{
          inspect(channel_number)
        }"
      )

      exists =
        Channels.exists({channel_number, tuple5}) or Channels.exists({peer_address, tuple5})

      do_channelbind(conn, channel_number, peer_address, tuple5, exists)
    else
      _ ->
        Logger.info("Required attributes not found during channel bind")
        Conn.response(conn, 400, "Bad Request")
    end
  end

  defp do_channelbind(conn, channel_number, peer_address, tuple5, false)
       when channel_number >= 0x4000 and channel_number <= 0x7FFE do
    case Store.lookup(tuple5) do
      {:ok, [client, {_relay_ip, _relay_port}, _, _]} ->
        AllocateClient.add_peer_channel(client, channel_number, peer_address)
        Conn.response(conn, :success)

      {:error, :not_found} ->
        Logger.info("Invalid channel number provided in request - 5tuple not available")
        Conn.response(conn, 400, "Bad Request")
    end
  end

  defp do_channelbind(conn, channel_number, peer_address, tuple5, true) do
    {:ok, [[client, _, _]]} = Channels.lookup({channel_number, peer_address, tuple5})
    Logger.debug("refreshing timer")
    AllocateClient.refresh_channel(client, channel_number)
    Conn.response(conn, :success)
  end

  defp do_channelbind(conn, _channel_number, _peer_address, _tuple5, _) do
    Logger.info(
      "Invalid channel number provided in request - channel number or peer address already in use"
    )

    Conn.response(conn, 400, "Bad Request")
  end
end
