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
