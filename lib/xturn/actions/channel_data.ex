### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### Redistribution and use in source and binary forms, with or without modification,
### are permitted provided that the following conditions are met:
###
### * Redistributions of source code must retain the above copyright notice, this
### list of conditions and the following disclaimer.
### * Redistributions in binary form must reproduce the above copyright notice,
### this list of conditions and the following disclaimer in the documentation
### and/or other materials provided with the distribution.
### * Neither the name of the authors nor the names of its contributors
### may be used to endorse or promote products derived from this software
### without specific prior written permission.
###
### THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
### EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
### WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
### DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
### DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
### (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
### LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
### ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
### (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
### SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
### ----------------------------------------------------------------------

defmodule Xirsys.XTurn.Actions.ChannelData do
  @doc """
  Handles incoming channel data. We route this directly to the peers, if they exist and
  have valid channels open.
  """
  require Logger
  alias Xirsys.XTurn.Channels.Store, as: Channels
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn

  def process(%Conn{is_control: true}) do
    Logger.debug("cannot send channel data on control connection")
    false
  end

  def process(%Conn{message: <<1::2, num::14, _length::16, data::binary>>} = conn) do
    channel = <<1::2, num::14>>

    Logger.debug(
      "channel data (#{byte_size(data)} bytes) received on channel #{inspect(channel)}"
    )

    proto = :_
    tuple5 = Tuple5.to_map(Tuple5.create(conn, proto))

    case Channels.lookup({channel, tuple5}) do
      {:ok, [[client, _peer_address, socket, channel_cache] | _tail]} ->
        # already short circuited
        AllocateClient.send_channel(client, channel, data, socket, channel_cache)
        conn

      {:error, :not_found} ->
        Logger.debug("channel #{inspect(channel)} does not exist in ETS")
        false
    end
  end
end
