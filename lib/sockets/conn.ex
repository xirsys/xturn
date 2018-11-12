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
        Socket.send(client_socket, Stun.encode(turn, turn.key), conn.client_ip, conn.client_port)
        conn
    end
  end
end
