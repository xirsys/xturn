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
    tup5 = [
      {:ca, conn.client_ip},
      {:cp, conn.client_port},
      {:sa, Socket.server_ip()},
      {:sp, conn.server_port},
      {:proto, Map.get(attrs, :requested_transport)}
    ]

    with false <- Store.exists(tup5) do
      conn
    else
      _ ->
        Logger.info(
          "Allocation already exists from ip:#{inspect(conn.client_ip)}, port:#{
            inspect(conn.client_port)
          }"
        )

        # Conn.response(conn, 437, "Allocation Mismatch")
        {:ok, [_client, {_ip, port}, _, _]} = Store.lookup(tup5)
        Logger.debug("#{inspect(port)}")

        nattrs = [
          # reservation_token: <<0::64>>,
          xor_mapped_address: {conn.client_ip, conn.client_port},
          xor_relayed_address: {Socket.server_ip(), port},
          lifetime: <<600::32>>
        ]

        Logger.debug("integrity = #{conn.decoded_message.integrity}")
        Logger.debug("Allocated")
        Conn.response(conn, :success, nattrs)
        Conn.halt(conn)
    end
  end
end
