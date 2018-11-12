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

defmodule Xirsys.XTurn.Actions.Refresh do
  @doc """
  Updates an allocations current expiry to its maximum set lifetime value
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("refreshing #{inspect(conn.decoded_message)}")

    with true <- Map.has_key?(attrs, :lifetime),
         val <- Map.get(attrs, :lifetime),
         tuple5 <- Tuple5.to_map(Tuple5.create(conn, :_)) do
      do_refresh(conn, val, tuple5)
    else
      _ ->
        Logger.info("LIFETIME attribute not found during refresh request")
        Conn.response(conn, 400, "Bad Request")
    end
  end

  defp do_refresh(conn, <<0::32>>, tuple5) do
    case Store.lookup(tuple5) do
      {:ok, [client, {_relay_ip, _relay_port}, _, _]} ->
        Logger.debug("Refreshing with 0 time")
        AllocateClient.refresh(client, 0)

      {:error, :not_found} ->
        Conn.response(conn, 437, "Allocation Mismatch")
    end
  end

  defp do_refresh(conn, <<b::32>>, tuple5) when is_integer(b) do
    b = if b > 600, do: 600, else: b

    case Store.lookup(tuple5) do
      {:ok, [client, {_relay_ip, _relay_port}, _, _]} ->
        AllocateClient.refresh(client, b)
        new_attrs = %{lifetime: <<b::32>>}
        Conn.response(conn, :success, new_attrs)

      {:error, :not_found} ->
        Conn.response(conn, 437, "Allocation Mismatch")
    end
  end

  defp do_refresh(conn, val, _) do
    Logger.info("Bad value #{inspect(val)} in refresh request")
    Conn.response(conn, 400, "Bad Request")
  end
end
