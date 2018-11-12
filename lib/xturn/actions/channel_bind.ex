### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### Redistribution and use in source and binary forms, with or without modification,
### are permitted provided that the following conditions are met:
###
### * Redistributions of source code must retain the above copyright notice, this
### list of conditions and the following disclaimer.
### * Redistributions in binary form must reproduce the above copyright notice,
### this list of conditions and the following disclaimer in the documentation
### and/or other materials provided with the distribution.
### * Neither the name of the authors nor the names of its contributors
### may be used to endorse or promote products derived from this software
### without specific prior written permission.
###
### THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
### EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
### WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
### DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
### DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
### (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
### LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
### ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
### (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
### SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
