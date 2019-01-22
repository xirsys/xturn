### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
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

defmodule Xirsys.Sockets.Client do
  @moduledoc """
  TCP protocol socket client for STUN connections
  """
  use GenServer
  require Logger
  @vsn "0"

  alias Xirsys.Sockets.Socket

  #####
  # External API

  @doc """
  Standard OTP module startup
  """
  def start_link(socket, callback, ssl) do
    GenServer.start_link(__MODULE__, [socket, callback, ssl])
  end

  def create(socket, callback, ssl) do
    Xirsys.Sockets.SockSupervisor.start_child(socket, callback, ssl)
  end

  def init([socket, callback, ssl]) do
    Logger.debug("Client init")

    {:ok,
     %{
       callback: callback,
       accepted: false,
       list_socket: socket,
       cli_socket: nil,
       addr: nil,
       turn_msg_buffer: <<>>,
       ssl: ssl
     }, 0}
  end

  @doc """
  Asynchronous socket response handler
  """
  def handle_cast({msg, ip, port}, %{cli_socket: socket} = state) do
    # Select proper client
    Logger.debug(
      "Dispatching TCP to #{inspect(ip)}:#{inspect(port)} | #{inspect(byte_size(msg))} bytes"
    )

    Socket.send(socket, msg)
    {:noreply, state}
  end

  def handle_cast(:stop, state),
    do: {:stop, :normal, state}

  def handle_cast(other, state) do
    Logger.debug("TCP client: strange cast: #{inspect(other)}")
    {:noreply, state}
  end

  def handle_call(other, _from, state) do
    Logger.debug("TCP client: strange call: #{inspect(other)}")
    {:noreply, state}
  end

  def handle_info(:timeout, %{list_socket: list_socket, callback: cb} = state) do
    Logger.debug("handle_info timeout #{inspect(cb)}")

    with {:ok, cli_socket} <- Socket.handshake(list_socket),
         {:ok, client_ip_port} <- Socket.peername(cli_socket),
         {:ok, {_, sport}} <- Socket.sockname(cli_socket) do
      Logger.debug("#{inspect(list_socket)}")
      create(list_socket, cb, false)
      Socket.set_sockopt(list_socket, cli_socket)
      Socket.setopts(cli_socket)
      Logger.debug("returning from timeout")

      {:noreply,
       %{
         state
         | accepted: true,
           cli_socket: cli_socket,
           addr: {client_ip_port, {Socket.server_ip(), sport}}
       }}
    end
  end

  @doc """
  Message handler for incoming STUN packets
  """
  def handle_info({_, _client, data}, %{cli_socket: socket} = state) do
    Logger.debug("handle_info tcp")

    with {:ok, ip_port} <- Socket.peername(socket) do
      Logger.debug("TCP called from #{inspect(ip_port)} with #{inspect(byte_size(data))} BYTES")

      new_buffer =
        Socket.process_buffer(socket, data, state.turn_msg_buffer, state.addr, state.callback)

      Socket.setopts(socket)
      {:noreply, %{state | :turn_msg_buffer => new_buffer}}
    end
  end

  def handle_info({:ssl_closed, client}, state) do
    Logger.debug("Client #{inspect(client)} closed connection")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_closed, client}, state) do
    Logger.debug("Client #{inspect(client)} closed connection")
    {:stop, :normal, state}
  end

  def handle_info(info, state) do
    Logger.debug("TCP client: strange info: #{inspect(info)}")
    {:noreply, state}
  end

  def terminate(
        reason,
        %{cli_socket: socket, list_socket: list_socket, callback: cb, accepted: false, ssl: ssl} =
          _state
      ) do
    create(list_socket, cb, ssl)
    Socket.close(socket)
    Logger.debug("TCP client closed: #{inspect(reason)}")
    :ok
  end

  def terminate(reason, %{cli_socket: socket} = _state) do
    Socket.close(socket)
    Logger.debug("TCP client closed: #{inspect(reason)}")
    :ok
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
