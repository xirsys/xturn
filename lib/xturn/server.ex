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
