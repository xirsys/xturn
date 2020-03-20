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

defmodule Xirsys.XTurn.Actions.HasRequestedTransport do
  @doc """
  Determines if a peer is assigned to a given transport type.
  Fixed to UDP as per TURN specification.
  """
  require Logger
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  @udp_proto <<17, 0, 0, 0>>

  # Documented in RFC5766, though not so useful when only one
  # transport type allowed
  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    # Requested transport in header?
    with true <- Map.has_key?(attrs, :requested_transport),
         # Requested transport should be UDP
         @udp_proto <- Map.get(attrs, :requested_transport) do
      conn
    else
      false ->
        # Requested transport not in header
        Logger.error(
          "Request transport not provided from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 400, "Bad Request")

      _ ->
        # Only UDP supported. Not a WebRTC app?
        Logger.error(
          "Unsupported transport protocol requested from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 442, "Unsupported Transport Protocol")
    end
  end
end
