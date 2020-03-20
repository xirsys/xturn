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

defmodule Xirsys.XTurn.Actions.NotAllocationExists do
  @doc """
  Checks if the current 5-tuple has previously been used. If so,
  then this is a duplicate allocation request and can be safely
  ignored.
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.Sockets.{Socket, Conn}
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    # Create 5Tuple match criteria for search
    tup5 = [
      {:ca, conn.client_ip},
      {:cp, conn.client_port},
      {:sa, Socket.server_ip()},
      {:sp, conn.server_port},
      {:proto, Map.get(attrs, :requested_transport)}
    ]

    # 5Tuple not yet exists?
    with false <- Store.exists(tup5) do
      # Then we're good
      conn
    else
      _ ->
        # 5Tuple already created.
        Logger.info(
          "Allocation already exists from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        # Conn.response(conn, 437, "Allocation Mismatch")
        {:ok, [_client, {_ip, port}, _, _]} = Store.lookup(tup5)

        nattrs = %{
          # reservation_token: <<0::64>>,
          xor_mapped_address: {conn.client_ip, conn.client_port},
          xor_relayed_address: {Socket.server_ip(), port},
          lifetime: <<600::32>>
        }

        # Respond positively, since this is not an error.
        Logger.debug("integrity = #{conn.decoded_message.integrity}")
        Logger.debug("Allocated")

        conn
        |> Conn.response(:success, nattrs)
        |> Conn.halt()
    end
  end
end
