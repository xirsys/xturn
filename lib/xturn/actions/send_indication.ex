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

  # Handles sending data from Client to Peer
  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("send indication #{inspect(conn.decoded_message)}")
    # Get 5Tuple lookup match
    tuple5 = Tuple5.to_map(Tuple5.create(conn, :_))

    # Data present in header? Receiver address present?
    with true <- Map.has_key?(attrs, :data) and Map.has_key?(attrs, :xor_peer_address),
         # Extract data
         data <- Map.get(attrs, :data),
         # Extract receiver address
         peer_address = {_pip, _port} <- Map.get(attrs, :xor_peer_address),
         # Get 5Tuple registration
         {:ok, [client, {_relay_ip, _relay_port}, socket, permission_cache]} <-
           Store.lookup(tuple5) do
      Logger.debug("sending indication to peer")
      # Transmit data to peer
      AllocateClient.send_indication(client, peer_address, data, socket, permission_cache)
      conn
    else
      {:error, _} ->
        # 5Tuple not present, so allocation must not be valid (or present)
        Logger.debug("client does not exist #{inspect(tuple5)} (send indication)")
        false

      _ ->
        # Missing data from STUN packet header
        Logger.debug("Required attributes not found during send indication")
        false
    end
  end
end
