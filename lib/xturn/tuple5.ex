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

defmodule Xirsys.XTurn.Tuple5 do
  @moduledoc """
  TURN allocation 5-Tuple object
  """
  alias Xirsys.Sockets.Conn
  alias Xirsys.XTurn.Tuple5

  @vsn "0"
  defstruct client_address: nil,
            client_port: nil,
            server_address: nil,
            server_port: nil,
            protocol: :udp

  def create(
        %Conn{client_ip: cip, client_port: cport, server_ip: sip, server_port: sport} = _conn,
        proto
      ) do
    %Tuple5{
      client_address: cip,
      client_port: cport,
      server_address: sip,
      server_port: sport,
      protocol: proto
    }
  end

  def to_map(%Tuple5{
        client_address: ca,
        client_port: cp,
        server_address: sa,
        server_port: sp,
        protocol: proto
      }) do
    [{:ca, ca}, {:cp, cp}, {:sa, sa}, {:sp, sp}, {:proto, proto}]
  end

  def from_map([{:ca, ca}, {:cp, cp}, {:sa, sa}, {:sp, sp}, {:proto, proto}]) do
    %Tuple5{
      client_address: ca,
      client_port: cp,
      server_address: sa,
      server_port: sp,
      protocol: proto
    }
  end
end
