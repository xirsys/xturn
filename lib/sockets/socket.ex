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

defmodule Xirsys.Sockets.Socket do
  @moduledoc """
  Socket protocol helpers
  """
  require Logger
  alias Xirsys.Sockets.{Socket, Conn}

  defstruct type: :udp, sock: nil

  @type t :: {
          type :: :udp | :tcp | :dtls | :tls,
          sock :: port()
        }

  @channel_msg 1
  @send_msg 0

  @setopts_default [{:active, :once}, :binary]

  @doc """
  Returns the server ip from config for packet use
  """
  @spec server_ip() :: tuple()
  def server_ip(),
    do: Application.get_env(:xturn, :server_ip, {0, 0, 0, 0})

  @doc """
  Returns the client message hooks from config
  """
  @spec client_hooks() :: list()
  def client_hooks() do
    case Application.get_env(:xturn, :client_hooks, []) do
      hooks when is_list(hooks) -> hooks
      _ -> []
    end
  end

  @doc """
  Returns the peer message hooks from config
  """
  @spec peer_hooks() :: list()
  def peer_hooks() do
    case Application.get_env(:xturn, :peer_hooks, []) do
      hooks when is_list(hooks) -> hooks
      _ -> []
    end
  end

  @doc """
  Returns the servers local ip from the config
  """
  @spec server_local_ip() :: tuple()
  def server_local_ip(),
    do: Application.get_env(:xturn, :server_local_ip, {0, 0, 0, 0})

  @doc """
  Opens a new port for UDP TURN transport
  """
  @spec open_turn_port(tuple(), atom(), list()) :: {:ok, Socket.t()} | {:error, atom()}
  def open_turn_port({_, _, _, _} = sip, policy, opts) do
    # [{:buffer, 1024*1024*1024}, {:recbuf, 1024*1024*1024}, {:sndbuf, 1024*1024*1024}, {:exit_on_close, true}, {:keepalive, true}, {:nodelay, true}, {:packet, :raw}]
    udp_options =
      [
        {:ip, sip},
        {:active, :once},
        {:buffer, 1024 * 1024 * 1024},
        {:recbuf, 1024 * 1024 * 1024},
        {:sndbuf, 1024 * 1024 * 1024},
        :binary
      ] ++ opts

    open_free_udp_port(policy, udp_options)
  end

  @doc """
  With new data, see if we can process a message on the buffer
  """
  @spec process_buffer(any(), binary(), binary(), tuple(), function()) :: binary()
  def process_buffer(socket, data, buffer, addr, callback) do
    bin = <<buffer::binary, data::binary>>
    process_buffer(socket, bin, addr, callback)
  end

  @doc """
  Performs the SSL/TLS/DTLS server-side handshake if a secure
  socket, otherwise simply accepts an incoming connection request
  on a listening socket.
  """
  @spec handshake(%Socket{}) :: {:ok, %Socket{}} | {:error, any()}
  def handshake(%Socket{type: :tcp, sock: socket}) do
    with {:ok, cli_socket} <- :gen_tcp.accept(socket) do
      {:ok, %Socket{type: :tcp, sock: cli_socket}}
    end
  end

  def handshake(%Socket{type: type, sock: socket}) do
    with {:ok, cli_socket} <- :ssl.transport_accept(socket),
         {:ok, cli_socket} <- :ssl.handshake(cli_socket) do
      {:ok, %Socket{type: type, sock: cli_socket}}
    end
  end

  @doc """
  Sends a message over an open udp socket port
  """
  @spec send(%Socket{}, binary(), tuple() | nil, integer() | nil) ::
          :ok | {:error, term()} | no_return()
  def send(socket, msg, ip \\ nil, port \\ nil)

  def send(%Socket{type: :udp, sock: socket}, msg, ip, port),
    do: :gen_udp.send(socket, ip, port, msg)

  def send(%Socket{type: :tcp, sock: socket}, msg, _, _),
    do: :gen_tcp.send(socket, msg)

  def send(%Socket{type: :dtls, sock: socket}, msg, _, _),
    do: :ssl.send(socket, msg)

  def send(%Socket{type: :tls, sock: socket}, msg, _, _),
    do: :ssl.send(socket, msg)

  @doc """
  Sends data to peer hooks
  """
  def send_to_peer_hooks(data) do
    peer_hooks()
    |> Enum.each(&GenServer.cast(&1, {:process_message, data}))
  end

  @doc """
  Sends data to client hooks
  """
  def send_to_client_hooks(data) do
    client_hooks()
    |> Enum.each(&GenServer.cast(&1, {:process_message, data}))
  end

  @doc """
  Sets one or more options for a socket.
  """
  @spec setopts(port() | %Socket{}, list()) :: :ok | {:error, term()}
  def setopts(socket, opts \\ @setopts_default)

  def setopts(%Socket{type: type, sock: socket}, opts) when type in [:udp, :tcp],
    do: :inet.setopts(socket, opts)

  def setopts(%Socket{type: _, sock: socket}, opts),
    do: :ssl.setopts(socket, opts)

  def setopts(socket, opts),
    do: :inet.setopts(socket, opts)

  def getopts(%Socket{type: type, sock: socket}) when type in [:tls, :dtls],
    do:
      :ssl.getopts(socket, [
        :active,
        :nodelay,
        :keepalive,
        :delay_send,
        :priority,
        :tos,
        :buffer,
        :recbuf,
        :sndbuf
      ])

  def getopts(%Socket{sock: socket}),
    do:
      :inet.getopts(socket, [
        :active,
        :nodelay,
        :keepalive,
        :delay_send,
        :priority,
        :tos,
        :buffer,
        :recbuf,
        :sndbuf
      ])

  @doc """
  Apply specific socket option for STUN connection
  """
  @spec set_sockopt(%Socket{}, %Socket{}) :: :ok
  def set_sockopt(%Socket{type: type} = list_sock, %Socket{type: type} = cli_socket)
      when type in [:tls, :dtls] do
    try do
      {:ok, opts} = getopts(list_sock)
      setopts(cli_socket, opts)
      :ok
    rescue
      e ->
        Logger.error("damn #{inspect(e)}")
        close(cli_socket)
    end
  end

  def set_sockopt(%Socket{type: :tcp} = list_sock, %Socket{type: :tcp} = cli_socket) do
    true = register_socket(cli_socket)

    try do
      {:ok, opts} = getopts(list_sock)
      setopts(cli_socket, opts)
      :ok
    rescue
      e ->
        Logger.error("damn #{inspect(e)}")
        close(cli_socket)
    end
  end

  def register_socket(%Socket{type: :tcp, sock: socket}),
    do: :inet_db.register_socket(socket, :inet_tcp)

  @doc """
  Returns the local address and port number for a socket.
  """
  @spec sockname(any()) ::
          {:ok, {tuple(), integer()}}
          | {:local, binary()}
          | {:unspec, <<>>}
          | {:undefined, any()}
          | {:error, term()}
  def sockname(%Socket{type: type, sock: socket}) when type in [:udp, :tcp],
    do: :inet.sockname(socket)

  def sockname(%Socket{type: type, sock: socket}) when type in [:dtls, :tls],
    do: :ssl.sockname(socket)

  @doc """
  Returns the peer address and port number for a socket.
  """
  @spec peername(any()) ::
          {:ok, {tuple(), integer()}}
          | {:local, binary()}
          | {:unspec, <<>>}
          | {:undefined, any()}
          | {:error, term()}
  def peername(%Socket{type: type, sock: socket}) when type in [:udp, :tcp],
    do: :inet.peername(socket)

  def peername(%Socket{type: type, sock: socket}) when type in [:dtls, :tls],
    do: :ssl.peername(socket)

  def port(%Socket{type: :udp, sock: sock}),
    do: :inet.port(sock)

  @doc """
  Closes a socket of any type.s
  """
  @spec close(Socket.t() | any(), any()) :: :ok
  def close(sock, reason \\ "")

  def close(%Socket{type: :udp, sock: socket}, reason) do
    :gen_udp.close(socket)
    Logger.debug("UDP listener closed: #{inspect(reason)}")
    :ok
  end

  def close(%Socket{type: :tcp, sock: socket}, reason) do
    :gen_tcp.close(socket)
    Logger.debug("UDP listener closed: #{inspect(reason)}")
    :ok
  end

  def close(%Socket{type: :dtls, sock: socket}, reason) do
    :ssl.close(socket)
    Logger.debug("DTLS listener closed: #{inspect(reason)}")
    :ok
  end

  def close(%Socket{type: :tls, sock: socket}, reason) do
    :ssl.close(socket)
    Logger.debug("TLS listener closed: #{inspect(reason)}")
    :ok
  end

  def close(_, _) do
    Logger.debug("Caught attempted close of nil socket")
    :ok
  end

  # ----------------------------
  # Private functions
  # ----------------------------

  defp process_buffer(_, bin, _, _) when byte_size(bin) <= 4, do: bin

  defp process_buffer(
         socket,
         <<type::2, _::14, body_bytes::16, _body::binary-size(body_bytes), _::binary>> = bin,
         addr,
         callback
       )
       when type == @send_msg or type == @channel_msg do
    msg_bytes = pad_body_bytes(type, body_bytes)
    process_data(bin, msg_bytes, socket, addr, callback)
  end

  defp process_buffer(_, <<type::2, _::14, _body_bytes::16, _::binary>> = bin, _, _)
       when type == @send_msg or type == @channel_msg,
       # message is not yet long enough
       do: bin

  defp process_buffer(_, <<type::2, _::14, _::binary>> = bin, _, _) do
    Logger.error("Unknown message type : #{inspect(type)}")
    bin
  end

  # With a packet header extracted from the buffer,  see
  # if we can process it
  # need more data
  defp process_data(bin, required_size, _, _, _) when required_size > byte_size(bin), do: bin

  defp process_data(bin, required_size, socket, {{cip, cport}, {sip, sport}}, callback)
       when required_size == byte_size(bin) do
    process_msg(callback, bin, {self(), socket, cip, cport, sip, sport})
    <<>>
  end

  defp process_data(bin, required_size, socket, {{cip, cport}, {sip, sport}} = addr, callback) do
    # parse TURN message
    <<turn::binary-size(required_size), tail::binary>> = bin
    Logger.debug("Tail is: #{inspect(tail)}")
    # ns = process_turn_msg(turn, %{state | turn_msg_buffer: bin})
    process_msg(callback, turn, {self(), socket, cip, cport, sip, sport})
    process_buffer(socket, tail, addr, callback)
  end

  defp pad_body_bytes(@channel_msg, bytes),
    do: roundup_to_4(bytes)

  defp pad_body_bytes(@send_msg, bytes),
    do: bytes + 20

  # Pad message if needed
  defp roundup_to_4(num) do
    pad = rem(num, 4)
    padded = num + (4 - pad)
    if rem(num, 4) == 0, do: padded, else: padded + 4
  end

  # Calls the callback handler
  defp process_msg(cb, msg, {listener, socket, fip, fport, tip, tport}) do
    conn = %Conn{
      message: msg,
      listener: listener,
      client_socket: socket,
      client_ip: fip,
      client_port: fport,
      server_ip: tip,
      server_port: tport
    }

    apply(cb, :process_message, [conn])
    send_to_client_hooks(conn)
  end

  # Opens an available UDP port as per requirement.
  # See RFC's
  defp open_free_udp_port(:random, udp_options) do
    ## BUGBUG: Should be a random port
    case :gen_udp.open(0, udp_options) do
      {:ok, socket} ->
        {:ok, %Socket{type: :udp, sock: socket}}

      {:error, reason} ->
        Logger.error("UDP open #{inspect(udp_options)} -> #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp open_free_udp_port({:range, min_port, max_port}, udp_options) when min_port <= max_port do
    case :gen_udp.open(min_port, udp_options) do
      {:ok, socket} ->
        {:ok, %Socket{type: :udp, sock: socket}}

      {:error, :eaddrinuse} ->
        policy2 = {:range, min_port + 1, max_port}
        open_free_udp_port(policy2, udp_options)

      {:error, reason} ->
        Logger.error("UDP open #{inspect([0 | udp_options])} -> #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp open_free_udp_port({:range, _min_port, _max_port}, udp_options) do
    reason = "Port range exhausted"
    Logger.error("UDP open #{inspect([0 | udp_options])} -> #{inspect(reason)}")
    {:error, reason}
  end

  defp open_free_udp_port({:preferred, port}, udp_options) do
    case :gen_udp.open(port, udp_options) do
      {:ok, socket} ->
        {:ok, %Socket{type: :udp, sock: socket}}

      {:error, :eaddrinuse} ->
        policy2 = :random
        open_free_udp_port(policy2, udp_options)

      {:error, reason} ->
        Logger.error("UDP open #{inspect([0 | udp_options])} -> #{inspect(reason)}")
        {:error, reason}
    end
  end
end
