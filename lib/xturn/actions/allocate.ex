### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2020 Jahred Love and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache
### License, Version 2.0. (the "License");
###
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###      http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
###
### See LICENSE for the full license text.
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
    # Acquire the transport type. Currently always :udp
    proto = Map.get(attrs, :requested_transport)

    # Socket setup for peer port on server
    opts =
      if Map.has_key?(attrs, :dont_fragment) and proto != @tcp_proto,
        do: [{:raw, 0, 10, <<2::native-size(32)>>}],
        else: []

    # Create a new 5Tuple reference. Overwrites if already exists.
    tuple5 = Tuple5.create(conn, proto)
    # TTL for the allocation is 600. This is standard
    lifetime = 600

    # Create the actual allocation process
    {:ok, pid} =
      AllocateClient.create(
        conn.decoded_message.transactionid,
        conn.client_socket,
        tuple5,
        lifetime
      )

    # Assign peer details to allocation. Currently, allocations support a single peer, since
    # WebRTC only supports single peers per allocation.
    AllocateClient.set_peer_details(pid, conn.decoded_message.ns, conn.decoded_message.peer_id)
    # Open the peer port
    {:ok, socket, port} = AllocateClient.open_port_random(pid, opts)
    # Get permission cache Agent process reference
    {:ok, permission_cache} = AllocateClient.get_permission_cache(pid)
    # Create relay IP / port tuple...
    relay_address = {Socket.server_ip(), port}
    # ...and assign it to the allocation
    AllocateClient.set_relay_address(pid, relay_address)

    # Store 5Tuple into local db
    Store.insert(
      conn.decoded_message.transactionid,
      pid,
      relay_address,
      tuple5,
      socket,
      permission_cache
    )

    # Build attributes to send back to client
    nattrs = %{
      # reservation_token: <<0::64>>,
      xor_mapped_address: {conn.client_ip, conn.client_port},
      xor_relayed_address: {Socket.server_ip(), port},
      lifetime: <<600::32>>
    }

    Logger.debug("integrity = #{conn.decoded_message.integrity}")
    # turn2 = %Stun{conn.decoded_message | integrity: :true}
    Logger.debug("Allocated")
    # Notify client
    Conn.response(conn, :success, nattrs)
  end
end
