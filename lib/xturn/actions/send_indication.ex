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
