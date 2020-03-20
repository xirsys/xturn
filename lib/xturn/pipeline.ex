### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2020 Jahred Love and Xirsys LLC <experts@xirsys.com>
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

defmodule Xirsys.XTurn.Pipeline do
  @moduledoc """
  provides handers for TURN over STUN
  """
  # import ExProf.Macro
  require Logger

  @stun_marker 0
  # @udp_proto <<17, 0, 0, 0>>
  # @tcp_proto <<6, 0, 0, 0>>

  alias Xirsys.Sockets.{Socket, Conn}
  alias Xirsys.XTurn.SockImpl

  alias XMediaLib.Stun

  @pipes Application.get_env(:xturn, :pipes)

  @doc """
  Encapsulates full STUN/TURN request stub. Must be called as
  separate process
  """
  @spec process_message(%Conn{}) :: %Conn{} | false
  def process_message(%Conn{message: <<@stun_marker::2, _::14, _rest::binary>> = msg} = conn) do
    Logger.debug("TURN Data received")
    {:ok, turn} = Stun.decode(msg)
    do_request(%Conn{conn | decoded_message: turn}) |> SockImpl.send()
  end

  @doc """
  Handles TURN Channel Data messages [RFC5766] section 11
  """
  def process_message(%Conn{message: <<1::2, _num::14, length::16, _rest::binary>>} = conn) do
    Logger.debug(
      "TURN channeldata request (length: #{length}) from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      }"
    )

    execute(conn, :channeldata)
  end

  @doc """
  Handles errored TURN message extraction
  """
  def process_message(%Conn{message: <<_::binary>>}) do
    Logger.error("Error in extracting TURN message")
    false
  end

  @doc """
  ### TODO: check to make sure all attributes are handled
  ### TODO: client TCP connection establishment [RFC6062] section 4.2

  attributes include:
    binding:          Handles STUN requests [RFC5389]
    allocate:         Handles TURN allocation requests [RFC5766] section 2.2 and section 5
    refresh:          Handles TURN refresh requests [RFC5766] section 7
    channelbind:      Handles TURN channelbind requests [RFC5766] section 11
    createperm:       Handles TURN createpermission requests [RFC5766] section 9
    send:             Handles TURN send indication requests [RFC5766] section 9
  """
  @spec do_request(%Conn{}) :: %Conn{} | false
  def do_request(%Conn{decoded_message: %Stun{class: :request, method: :binding}} = conn) do
    Logger.debug(
      "STUN request from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      } with ip:#{inspect(conn.server_ip)}, port:#{inspect(conn.server_port)}"
    )

    attrs = %{
      xor_mapped_address: {conn.client_ip, conn.client_port},
      mapped_address: {conn.client_ip, conn.client_port},
      response_origin: {Socket.server_ip(), conn.server_port}
    }

    Conn.response(conn, :success, attrs)
  end

  def do_request(%Conn{decoded_message: %Stun{class: class, method: method}} = conn)
      when class in [:request, :indication] do
    Logger.debug(
      "TURN #{method} #{class} from client at ip:#{inspect(conn.server_ip)}, port:#{
        inspect(conn.server_port)
      }"
    )

    execute(conn, method)
  end

  def do_request(false) do
    Logger.error("Error: STUN process halted by server")
    false
  end

  def do_request(_) do
    Logger.error("Error in processing STUN message")
    false
  end

  # executes a given list of actions against a connection
  defp execute(%Conn{} = conn, pipe) when is_atom(pipe) do
    @pipes
    |> Map.get(pipe, [])
    |> Enum.reduce(conn, &process/2)
  end

  defp process(_, %Conn{halt: true} = conn), do: conn

  defp process(action, conn), do: apply(action, :process, [conn])
end
