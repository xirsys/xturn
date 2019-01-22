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

defmodule Xirsys.Sockets.Conn do
  @moduledoc """
  TURN connection object
  """
  require Logger

  alias Xirsys.Sockets.{Conn, Response, Socket}
  alias XMediaLib.Stun

  @vsn "0"
  @realm "xirsys.com"
  @software "xirsys-turnserver"
  @nonce "5543438859252a7c"

  defstruct listener: nil,
            message: nil,
            decoded_message: nil,
            client_socket: nil,
            client_ip: nil,
            client_port: nil,
            server_ip: nil,
            server_port: nil,
            is_control: false,
            force_auth: false,
            response: nil,
            halt: nil

  def halt(%Conn{} = conn),
    do: %Conn{conn | halt: true}

  @spec response(%Conn{}, atom() | integer(), binary() | any()) :: %Conn{}
  def response(conn, class, attrs \\ nil)

  def response(%Conn{} = conn, class, attrs) when is_atom(class),
    do: %Conn{conn | response: %Response{class: class, attrs: attrs}}

  def response(%Conn{} = conn, err, msg) when is_integer(err),
    do: %Conn{conn | response: %Response{err_no: err, message: msg}} |> Conn.halt()

  @doc """
  If a response message has been set, then we must notify the client according
  to the STUN and TURN specifications.
  """
  @spec send(%Conn{}) :: %Conn{}
  def send(%Conn{response: %Response{err_no: err, message: msg}} = conn) when is_integer(err) do
    conn
    |> build_response(err, msg)
    |> respond()
  end

  def send(%Conn{response: %Response{class: cls, attrs: attrs}} = conn) when is_atom(cls) do
    conn
    |> build_response(cls, attrs)
    |> respond()
  end

  def send(%Conn{} = conn) do
    Logger.info("SEND: #{inspect(conn)}")
    conn
  end

  def send(v) do
    Logger.info("SEND: #{inspect(v)}")
    v
  end

  @spec build_response(%Conn{}, atom() | integer(), binary() | any()) :: %Conn{}
  defp build_response(%Conn{decoded_message: %Stun{} = turn} = conn, class, attrs)
       when is_atom(class) do
    new_attrs =
      cond do
        is_map(attrs) ->
          Map.put(attrs, :software, @software)

        true ->
          %{software: @software}
      end

    fingerprint = turn.integrity
    Logger.info("#{inspect(new_attrs)}")

    %Conn{
      conn
      | decoded_message: %Stun{turn | class: class, fingerprint: fingerprint, attrs: new_attrs}
    }
  end

  defp build_response(%Conn{decoded_message: %Stun{} = turn} = conn, err_no, err_msg)
       when is_integer(err_no) do
    new_attrs = %{
      error_code: {err_no, err_msg},
      nonce: @nonce,
      realm: @realm,
      software: @software
    }

    %Conn{conn | decoded_message: %Stun{turn | class: :error, attrs: new_attrs}}
  end

  @spec respond(%Conn{}) :: %Conn{}
  defp respond(%Conn{decoded_message: %Stun{} = turn} = conn) do
    case conn.client_socket do
      nil ->
        conn

      client_socket ->
        Socket.send(client_socket, Stun.encode(turn), conn.client_ip, conn.client_port)
        conn
    end
  end
end
