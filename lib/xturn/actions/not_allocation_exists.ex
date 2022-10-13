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

defmodule XTurn.Actions.NotAllocationExists do
  @doc """
  Checks if the current 5-tuple has previously been used. If so,
  then this is a duplicate allocation request and can be safely
  ignored.
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils}

  def process(%Conn{halt: true} = conn), do: conn

  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid} = turn,
          socket: socket,
          client_addr: {client_ip, client_port},
          state: state
        } = conn
      ) do
    Logger.debug("not_allocation_exists")
    allocation = Map.get(state, :allocation, 0)

    case is_integer(allocation) and allocation > Utils.timestamp() do
      false ->
        conn

      _ ->
        {:ok, {server_ip, server_port}} = :inet.sockname(socket)

        Logger.info(
          "Allocation already exists from ip:#{inspect(client_ip)}, port:#{inspect(client_port)}"
        )

        nattrs = %{
          # reservation_token: <<0::64>>,
          xor_mapped_address: {client_ip, client_port},
          xor_relayed_address: {server_ip, server_port},
          lifetime: <<600::32>>
        }

        lifetime = Utils.timestamp() + 600
        state = Map.put(state, :allocation, lifetime)

        # Respond positively, since this is not an error.
        Logger.debug("integrity = #{turn.integrity}")
        Logger.debug("Allocated")

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :success, method: method, transactionid: tid, attrs: nattrs},
            state: state
        }
    end
  end
end
