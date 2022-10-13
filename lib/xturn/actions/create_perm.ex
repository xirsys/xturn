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

defmodule XTurn.Actions.CreatePerm do
  @doc """
  Assigns a permission for a peer on a given client allocation
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils, PeerImpl}

  @nonce Application.get_env(:xturn, :nonce)
  @realm Application.get_env(:xturn, :realm)

  def process(%Conn{halt: true} = conn), do: conn

  # Associates a peer reflexive IP and port with a given allocation session
  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid, attrs: attrs} = turn,
          socket: socket,
          client_addr: caddr,
          state: state
        } = conn
      ) do
    Logger.debug("creating a permission")

    # Extract peer address
    with {_ip, _port} = p <- Map.get(attrs, :xor_peer_address),
         ttl <- Map.get(state, :allocation, 0),
         true <- ttl > Utils.timestamp() do
      Logger.debug("createperm")

      permissions = Map.get(state, :permissions, [])

      permissions =
        case Enum.find_index(permissions, fn {addr, _} -> addr == p end) do
          nil ->
            [{p, Utils.timestamp() + 600} | permissions]

          indx when is_integer(indx) ->
            List.replace_at(permissions, indx, {p, Utils.timestamp() + 600})
        end

      PeerImpl.set_permissions(caddr, permissions)

      %Conn{
        conn
        | resp: %Stun{class: :success, method: method, transactionid: tid, key: Map.get(state, :key), attrs: attrs},
          state: Map.put(state, :permissions, permissions)
      }
    else
      false ->
        # No allocation registered for 5Tuple
        Logger.debug("client does not exist (createperm)")

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {400, "Bad Request"})

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }

      _ ->
        # Permission data not present in packet
        Logger.debug("no permissions sent")

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {400, "Bad Request"})

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }
    end
  end
end
