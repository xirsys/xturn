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

defmodule Xirsys.Sockets.Listener.TCP do
  @moduledoc """
  TCP protocol socket listener for STUN connections. Dispatches to TCP
  clients once listener socket has been set up.
  """
  use GenServer
  require Logger
  alias Xirsys.Sockets.Socket
  @vsn "0"

  @buf_size 1024 * 1024 * 16
  @opts [
    reuseaddr: true,
    keepalive: true,
    backlog: 30,
    active: false,
    buffer: @buf_size,
    recbuf: @buf_size,
    sndbuf: @buf_size
  ]

  #####
  # External API

  @doc """
  Standard OTP module startup
  """
  def start_link(cb, ip, port) do
    GenServer.start_link(__MODULE__, [cb, ip, port, false])
  end

  def start_link(cb, ip, port, ssl) do
    GenServer.start_link(__MODULE__, [cb, ip, port, ssl])
  end

  @doc """
  Initialises connection with IPv6 address
  """
  def init([cb, {_, _, _, _, _, _, _, _} = ip, port, ssl]) do
    opts = @opts ++ [ip: ip] ++ [:binary, :inet6]
    open_socket(cb, ip, port, ssl, opts)
  end

  @doc """
  Initialises connection with IPv4 address
  """
  def init([cb, {_, _, _, _} = ip, port, ssl]) do
    opts = @opts ++ [ip: ip] ++ [:binary]
    open_socket(cb, ip, port, ssl, opts)
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, %{:listener => listener} = _state) do
    Socket.close(listener)
    :ok
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  defp open_socket(cb, ip, port, ssl, opts) do
    with true <- valid_ip?(ip) do
      {:ok, socket} =
        case ssl do
          true ->
            {:ok, certs} = :application.get_env(:certs)
            nopts = opts ++ certs
            {:ok, sock} = :ssl.listen(port, nopts)
            {:ok, %Socket{type: :tls, sock: sock}}

          _ ->
            {:ok, sock} = :gen_tcp.listen(port, opts)
            {:ok, %Socket{type: :tcp, sock: sock}}
        end

      Xirsys.Sockets.Client.create(socket, cb, ssl)
      Logger.info("TCP listener started at [#{:inet_parse.ntoa(ip)}:#{port}]")
      {:ok, %{listener: socket, ssl: ssl}}
    else
      _ -> {:error, :invalid_ip_address}
    end
  end

  defp valid_ip?(ip),
    do: Enum.reduce(Tuple.to_list(ip), true, &(is_integer(&1) and &1 >= 0 and &1 < 65535 and &2))
end
