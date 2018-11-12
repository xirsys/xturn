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

defmodule Xirsys.XTurn.Actions.HasRequestedTransport do
  @doc """
  Determines if a peer is assigned to a given transport type.
  Fixed to UDP as per TURN specification.
  """
  require Logger
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  @udp_proto <<17, 0, 0, 0>>

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    with true <- Map.has_key?(attrs, :requested_transport),
         @udp_proto <- Map.get(attrs, :requested_transport) do
      conn
    else
      false ->
        Logger.error(
          "Request transport not provided from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 400, "Bad Request")

      _ ->
        Logger.error(
          "Unsupported transport protocol requested from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        Conn.response(conn, 442, "Unsupported Transport Protocol")
    end
  end
end
