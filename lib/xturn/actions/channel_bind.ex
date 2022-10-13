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

defmodule XTurn.Actions.ChannelBind do
  @doc """
  Channel binds a peer to a given client allocation
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils, PeerImpl}

  @nonce Application.get_env(:xturn, :nonce)
  @realm Application.get_env(:xturn, :realm)

  def process(%Conn{halt: true} = conn), do: conn

  def process(
        %Conn{
          turn: %Stun{method: method, transactionid: tid, attrs: attrs},
          socket: socket,
          client_addr: caddr,
          state: state
        } = conn
      ) do
    Logger.debug("channel binding")

    ts = Utils.timestamp()

    # Do the attributes contain a channel number and peer address pair?
    with {true, :xpa} <-
           {Map.has_key?(attrs, :channel_number) and Map.has_key?(attrs, :xor_peer_address), :xpa},
         # Extract channel number from binary
         <<channel_number::16, _::16>> <- Map.get(attrs, :channel_number),
         # Extract peer address
         peer_address = {_, _} <- Map.get(attrs, :xor_peer_address),
         allocation <- Map.get(state, :allocation),
         {true, :allocation} <- {allocation > ts, :allocation} do
      lifetime = Utils.timestamp() + 600
      PeerImpl.set_channel(caddr, channel_number, lifetime)

      state =
        Map.put(state, :channel_number, {channel_number, peer_address})
        |> Map.put(:channel_ttl, lifetime)

      Logger.debug("state is now: #{inspect(state)}")

      %Conn{
        conn
        | resp: %Stun{class: :success, method: method, transactionid: tid, key: Map.get(state, :key), attrs: %{}},
          state: state
      }
    else
      _ ->
        Logger.info("Required attributes not found during channel bind")

        nattrs = Map.put(attrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)
        nattrs = Map.put(nattrs, :error_code, {400, "Bad Request"})
    end
  end
end
