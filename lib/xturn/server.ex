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

defmodule Xirsys.XTurn.Server do
  @moduledoc """
  Provides implementation of STUN application by managing socket
  messages through use of the STUN protocol module.
  """
  use GenServer
  @vsn "0"

  #####
  # External API
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #########################################################################################################################
  # OTP functions
  #########################################################################################################################

  def init([]) do
    # {:ok, node_name} = :application.get_env(:node_name)
    # {:ok, node_host} = :application.get_env(:node_host)
    # {:ok, _} = Node.start(String.to_atom("#{node_name}@#{node_host}"))
    # {:ok, cookie} = :application.get_env(:cookie)
    # Node.set_cookie(cookie)
    {:ok, {}}
  end
end
