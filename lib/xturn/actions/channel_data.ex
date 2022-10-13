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

# defmodule XTurn.Actions.ChannelData do
#   @doc """
#   Handles incoming channel data. We route this directly to the peers, if they exist and
#   have valid channels open.
#   """
#   require Logger
#   alias XTurn.Channels.Store, as: Channels
#   alias XTurn.Allocate.Client, as: AllocateClient
#   alias XTurn.Tuple5
#   alias Xirsys.Sockets.Conn

#   def process(%Conn{is_control: true}) do
#     Logger.debug("cannot send channel data on control connection")
#     false
#   end

#   # If packet has a channel data header, then process as channel data throughput
#   def process(
#         %Conn{message: <<channel::16, len::16, data::binary-size(len), _rest::binary>>, cache: %{channel: [client, peer_address, socket]}} = conn
#       ) do
#     Logger.debug(
#       "fast channel data (#{byte_size(data)} bytes) received on channel #{inspect(channel)}, #{len} == #{byte_size(data)}"
#     )

#     AllocateClient.send_channel(client, channel, data, peer_address, socket)
#     conn
#   end

#   # If packet has a channel data header, then process as channel data throughput
#   def process(
#         %Conn{message: <<channel::16, len::16, data::binary-size(len), _rest::binary>>, cache: cache} = conn
#       ) do
#     Logger.debug(
#       "slow channel data (#{byte_size(data)} bytes) received on channel #{inspect(channel)}, #{len} == #{byte_size(data)}"
#     )
#     Logger.debug("#{inspect cache}")

#     # Match on any protocol (though only :udp should exist)
#     proto = :_
#     # Retrieve 5Tuple
#     tuple5 = Tuple5.to_map(Tuple5.create(conn, proto))

#     # Get channel permission / registration
#     case Channels.lookup({channel, tuple5}) do
#       {:ok, [[client, peer_address, socket, _channel_cache] | _tail]} ->
#         # already short circuited
#         AllocateClient.send_channel(client, channel, data, peer_address, socket)
#         conn

#       {:error, :not_found} ->
#         Logger.debug(
#           "channel #{inspect(channel)} does not exist in ETS for tuple #{inspect(tuple5)}"
#         )

#         Logger.debug("existing channels: #{inspect(Channels.to_list())}")
#         false
#     end
#   end
# end
