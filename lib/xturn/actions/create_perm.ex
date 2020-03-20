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

defmodule Xirsys.XTurn.Actions.CreatePerm do
  @doc """
  Assigns a permission for a peer on a given client allocation
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  # Associates a peer reflexive IP and port with a given allocation session
  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("creating a permission #{inspect(conn.decoded_message)}")
    # Get associated 5Tuple
    tuple5 = Tuple5.to_map(Tuple5.create(conn, :_))

    # Extract peer address
    with {_ip, _port} = p <- Map.get(attrs, :xor_peer_address),
         # Lookup allocation from store
         {:ok, [client, _peer_address, _, _]} <- Store.lookup(tuple5) do
      Logger.debug("createperm #{inspect(client)}, #{inspect(p)}")
      AllocateClient.add_permissions(client, p)
      Conn.response(conn, :success)
    else
      {:error, _} ->
        # No allocation registered for 5Tuple
        Logger.debug("client does not exist #{inspect(tuple5)} (createperm)")
        Conn.response(conn, 400, "Bad Request")

      _ ->
        # Permission data not present in packet
        Logger.debug("no permissions sent")
        Conn.response(conn, 400, "Bad Request")
    end
  end
end
