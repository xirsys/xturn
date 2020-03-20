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
