### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2022 Jahred Love and Xirsys LLC <experts@xirsys.com>
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

defmodule XTurn.Actions.Allocate do
  @doc """
  Dispatches a new process to cater for the client and his/her peers, whether
  send/receive or channels.
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils, PeerImpl, PeerSupervisor}

  @tcp_proto <<6, 0, 0, 0>>
  @software "XTurn 2.0"

  def process(%Conn{halt: true} = conn), do: conn

  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid, attrs: attrs},
          socket: socket,
          client_addr: {client_ip, client_port} = client_addr,
          transport: transport,
          state: state
        } = conn
      ) do
    Logger.debug("allocating")
    # Acquire the transport type. Currently always :udp
    proto = Map.get(attrs, :requested_transport)

    # Socket setup for peer port on server
    opts =
      if Map.has_key?(attrs, :dont_fragment) and proto != @tcp_proto,
        do: [{:raw, 0, 10, <<2::native-size(32)>>}],
        else: []

    # TTL for the allocation is 600. This is standard
    lifetime = Utils.timestamp() + 600
    state = Map.put(state, :allocation, lifetime)

    # Open the peer port
    {:ok, psocket} =
      :gen_udp.open(0, [
        {:buffer, 1024 * 1024 * 1024},
        {:recbuf, 1024 * 1024 * 1024},
        {:sndbuf, 1024 * 1024 * 1024},
        :binary
      ])

    state = Map.put(state, :peer_socket, psocket)

    {:ok, {server_ip, server_port}} = :inet.sockname(psocket)

    peer_name = PeerImpl.impl_name({client_ip, client_port})

    {:ok, pid} = PeerSupervisor.start_peer(peer_name, psocket, socket, client_addr, transport)

    PeerImpl.set_allocation({client_ip, client_port}, lifetime)

    :gen_udp.controlling_process(psocket, pid)

    # Build attributes to send back to client
    nattrs = %{
      # reservation_token: <<0::64>>,
      xor_relayed_address: {server_ip, server_port},
      xor_mapped_address: {client_ip, client_port},
      lifetime: <<600::32>>,
      software: @software
    }

    %Conn{
      conn
      | resp: %Stun{class: :success, method: method, transactionid: tid, key: Map.get(state, :key), attrs: nattrs},
        state: state
    }
  end
end
