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

defmodule XTurn.Actions.SendIndication do
  @doc """
  Sends data to a given peer
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils}

  @nonce Application.get_env(:xturn, :nonce)
  @realm Application.get_env(:xturn, :realm)

  def process(%Conn{halt: true} = conn), do: conn

  # Handles sending data from Client to Peer
  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid, attrs: attrs} = turn,
          state: state
        } = conn
      ) do
    # Data present in header? Receiver address present?
    with ts <- Utils.timestamp(),
         {ttl, :allocation} when ttl > ts <- {Map.get(state, :allocation, 0), :allocation},
         {psocket, :peer_socket} <- {Map.get(state, :peer_socket, nil), :peer_socket},
         # Extract data
         {data, :data} when not is_nil(data) <- {Map.get(attrs, :data), :data},
         # Extract receiver address
         {{pip, pport}, :xor_peer_address} <-
           {Map.get(attrs, :xor_peer_address), :xor_peer_address},
         {info, :port} when not is_nil(info) <- {Port.info(psocket), :port} do
      Logger.debug("sending indication to peer #{inspect({pip, pport})}")
      # Transmit data to peer
      :gen_udp.send(psocket, pip, pport, data)
      nil
    else
      false ->
        # 5Tuple not present, so allocation must not be valid (or present)
        Logger.debug("client does not exist (send indication)")

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {401, "Unauthorized"})

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }

      {_, :allocation} ->
        Logger.debug("No valid allocation")
        nil

      {data, :data} ->
        # Missing data from STUN packet header
        Logger.debug("No data in request #{inspect(data)}")
        nil

      {peer_address, :xor_peer_address} ->
        # Missing data from STUN packet header
        Logger.debug("XOR peer address not valid or present #{inspect(peer_address)}")
        nil

      {_, :port} ->
        Logger.debug("Peer port not valid or closed")
        nil
    end
  end
end
