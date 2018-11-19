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

defmodule Xirsys.Sockets.SockSupervisor do
  use Supervisor
  require Logger

  def start_link() do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  def start_child(sock, cb, ssl) do
    :supervisor.start_child(__MODULE__, [sock, cb, ssl])
  end

  def terminate_child(child) do
    :supervisor.terminate_child(__MODULE__, child)
  end

  def init([]) do
    tree = [worker(Xirsys.Sockets.Client, [], restart: :temporary)]
    supervise(tree, strategy: :simple_one_for_one)
  end
end
