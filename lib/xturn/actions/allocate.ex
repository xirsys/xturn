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

defmodule Xirsys.XTurn.Actions.Allocate do
  @doc """
  Dispatches a new process to cater for the client and his/her peers, whether
  send/receive or channels.
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.{Socket, Conn}
  alias XMediaLib.Stun

  @tcp_proto <<6, 0, 0, 0>>

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("allocating #{inspect(conn.decoded_message)}")
    proto = Map.get(attrs, :requested_transport)

    opts =
      if Map.has_key?(attrs, :dont_fragment) and proto != @tcp_proto,
        do: [{:raw, 0, 10, <<2::native-size(32)>>}],
        else: []

    tuple5 = Tuple5.create(conn, proto)
    lifetime = 600

    {:ok, pid} =
      AllocateClient.create(
        conn.decoded_message.transactionid,
        conn.client_socket,
        tuple5,
        lifetime
      )

    AllocateClient.set_peer_details(pid, conn.decoded_message.ns, conn.decoded_message.peer_id)
    {:ok, socket, port} = AllocateClient.open_port_random(pid, opts)
    {:ok, permission_cache} = AllocateClient.get_permission_cache(pid)
    relay_address = {Socket.server_ip(), port}
    AllocateClient.set_relay_address(pid, relay_address)

    Store.insert(
      conn.decoded_message.transactionid,
      pid,
      relay_address,
      tuple5,
      socket,
      permission_cache
    )

    nattrs = %{
      # reservation_token: <<0::64>>,
      xor_mapped_address: {conn.client_ip, conn.client_port},
      xor_relayed_address: {Socket.server_ip(), port},
      lifetime: <<600::32>>
    }

    Logger.debug("integrity = #{conn.decoded_message.integrity}")
    # turn2 = %Stun{conn.decoded_message | integrity: :true}
    Logger.debug("Allocated")
    Conn.response(conn, :success, nattrs)
  end
end
