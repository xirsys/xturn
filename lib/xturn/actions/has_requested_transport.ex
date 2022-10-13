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

defmodule XTurn.Actions.HasRequestedTransport do
  @doc """
  Determines if a peer is assigned to a given transport type.
  Fixed to UDP as per TURN specification.
  """
  require Logger
  alias XTurn.{Stun, Conn}

  @udp_proto <<17, 0, 0, 0>>
  @nonce Application.get_env(:xturn, :nonce)
  @realm Application.get_env(:xturn, :realm)

  # Documented in RFC5766, though not so useful when only one
  # transport type allowed
  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid, attrs: attrs} = turn,
          socket: socket
        } = conn
      ) do
    Logger.debug("has requested transport")
    # Requested transport in header?
    with true <- Map.has_key?(attrs, :requested_transport),
         # Requested transport should be UDP
         @udp_proto <- Map.get(attrs, :requested_transport) do
      conn
    else
      false ->
        # Requested transport not in header
        {:ok, {client_ip, client_port}} = :inet.peername(socket)

        Logger.error(
          "Request transport not provided from ip:#{inspect(client_ip)}, port:#{inspect(client_port)}"
        )

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {400, "Bad Request"})

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }

      _ ->
        # Only UDP supported. Not a WebRTC app?
        {:ok, {client_ip, client_port}} = :inet.peername(socket)

        Logger.error(
          "Unsupported transport protocol requested from ip:#{inspect(client_ip)}, port:#{inspect(client_port)}"
        )

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {442, "Unsupported Transport Protocol"})

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }
    end
  end
end
