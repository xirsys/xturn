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

defmodule Xirsys.Sockets.Listener.UDP do
  @moduledoc """
  UDP protocol socket handler for STUN connections
  """
  use GenServer
  require Logger
  @vsn "0"

  @buf_size 1024 * 1024 * 1024
  @opts [active: false, buffer: @buf_size, recbuf: @buf_size, sndbuf: @buf_size]

  alias Xirsys.Sockets.{Socket, Conn}

  #####
  # External API

  @doc """
  Standard OTP module startup
  """
  def start_link(cb, ip, port) do
    GenServer.start_link(__MODULE__, [cb, ip, port, false])
  end

  def start_link(cb, ip, port, ssl) do
    GenServer.start_link(__MODULE__, [cb, ip, port, ssl], debug: [:statistics])
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

  def handle_call(other, _from, state) do
    Logger.error("UDP listener: strange call: #{inspect(other)}")
    {:noreply, state}
  end

  @doc """
  Asynchronous socket response handler
  """
  def handle_cast({msg, ip, port}, state) do
    Socket.send(state.socket, msg, ip, port)
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_cast(other, state) do
    Logger.error("UDP listener: strange cast: #{inspect(other)}")
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Socket.setopts(state.socket)
    :erlang.process_flag(:priority, :high)
    {:noreply, state}
  end

  @doc """
  Message handler for incoming UDP STUN packets
  """
  def handle_info({:udp, _fd, fip, fport, msg}, state) do
    Logger.debug("UDP called #{inspect(byte_size(msg))} bytes")
    {:ok, {_, tport}} = Socket.sockname(state.socket)

    spawn(state.callback, :process_message, [
      %Conn{
        message: msg,
        listener: self(),
        client_socket: state.socket,
        client_ip: fip,
        client_port: fport,
        server_ip: Socket.server_ip(),
        server_port: tport
      }
    ])

    Socket.setopts(state.socket)
    :erlang.process_flag(:priority, :high)
    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.error("UDP listener: strange info: #{inspect(info)}")
    {:noreply, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(reason, state) do
    Socket.close(state.socket, reason)
    :ok
  end

  defp open_socket(cb, ip, port, ssl, opts) do
    Logger.info("UDP listener #{inspect(self())} started at [#{:inet_parse.ntoa(ip)}:#{port}]")

    with true <- valid_ip?(ip) do
      case ssl do
        true ->
          {:ok, certs} = :application.get_env(:certs)
          nopts = opts ++ certs ++ [protocol: :dtls]
          {:ok, fd} = :ssl.listen(port, nopts)
          fd = %Socket{type: :dtls, sock: fd}
          Xirsys.Sockets.Client.create(fd, cb, ssl)
          {:ok, %{listener: fd, ssl: ssl}}

        _ ->
          {:ok, fd} = :gen_udp.open(port, opts)
          {:ok, %{socket: %Socket{type: :udp, sock: fd}, callback: cb, ssl: ssl}, 0}
      end
    else
      false -> {:error, :invalid_ip_address}
      e -> e
    end
  end

  defp valid_ip?(ip),
    do: Enum.reduce(Tuple.to_list(ip), true, &(is_integer(&1) and &1 >= 0 and &1 < 65535 and &2))
end
