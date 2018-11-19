### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache License, Version 2.0.
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule Xirsys.XTurn.Pipeline do
  @moduledoc """
  provides handers for TURN over STUN
  """
  # import ExProf.Macro
  require Logger
  @vsn "0"

  @stun_marker 0
  # @udp_proto <<17, 0, 0, 0>>
  # @tcp_proto <<6, 0, 0, 0>>

  alias Xirsys.Sockets.{Socket, Conn}

  alias Xirsys.XTurn.Actions.{
    Allocate,
    Authenticates,
    ChannelBind,
    ChannelData,
    CreatePerm,
    HasRequestedTransport,
    NotAllocationExists,
    Refresh,
    SendIndication
  }

  alias XMediaLib.Stun

  @allocation [HasRequestedTransport, NotAllocationExists, Authenticates, Allocate]
  @refresh [Authenticates, Refresh]
  @channelbind [Authenticates, ChannelBind]
  @createpermission [Authenticates, CreatePerm]
  @indication [SendIndication]
  @channeldata [ChannelData]

  @doc """
  Encapsulates full STUN/TURN request stub. Must be called as
  separate process
  """
  @spec process_message(%Conn{}) :: %Conn{} | false
  def process_message(%Conn{message: <<@stun_marker::2, _::14, _rest::binary>> = msg} = conn) do
    Logger.debug("TURN Data received")
    {:ok, turn} = Stun.decode(msg)
    do_request(%Conn{conn | decoded_message: turn}) |> Conn.send()
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

    execute(conn, @channeldata)
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
    allocation:       Handles TURN allocation requests [RFC5766] section 2.2 and section 5
    refresh:          Handles TURN refresh requests [RFC5766] section 7
    channelbind:      Handles TURN channelbind requests [RFC5766] section 11
    createpermission: Handles TURN createpermission requests [RFC5766] section 9
    indication:       Handles TURN send indication requests [RFC5766] section 9
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

  def do_request(%Conn{decoded_message: %Stun{class: :request, method: :allocate}} = conn) do
    Logger.debug(
      "TURN allocation request from client at ip:#{inspect(conn.server_ip)}, port:#{
        inspect(conn.server_port)
      }"
    )

    execute(conn, @allocation)
  end

  def do_request(%Conn{decoded_message: %Stun{class: :request, method: :refresh}} = conn) do
    Logger.debug(
      "TURN refresh request from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      }"
    )

    execute(conn, @refresh)
  end

  def do_request(%Conn{decoded_message: %Stun{class: :request, method: :channelbind}} = conn) do
    Logger.debug(
      "TURN channelbind request from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      }"
    )

    execute(conn, @channelbind)
  end

  def do_request(%Conn{decoded_message: %Stun{class: :request, method: :createperm}} = conn) do
    Logger.debug(
      "TURN createpermission request from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      }"
    )

    execute(conn, @createpermission)
  end

  def do_request(%Conn{decoded_message: %Stun{class: :indication, method: :send}} = conn) do
    Logger.debug(
      "TURN send indication request from client at ip:#{inspect(conn.client_ip)}, port:#{
        inspect(conn.client_port)
      }"
    )

    execute(conn, @indication)
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
  defp execute(%Conn{} = conn, actions) when is_list(actions),
    do: Enum.reduce(actions, conn, &process/2)

  defp process(_, %Conn{halt: true} = conn), do: conn

  defp process(action, conn), do: apply(action, :process, [conn])
end
