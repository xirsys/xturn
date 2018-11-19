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

defmodule Xirsys.XTurn.Allocate.Supervisor do
  use Supervisor
  require Logger

  def start_link(alloc) do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, alloc)
  end

  def start_child(id, listener, tuple5, lifetime) do
    :supervisor.start_child(__MODULE__, [id, listener, tuple5, lifetime])
  end

  def terminate_child(child) do
    :supervisor.terminate_child(__MODULE__, child)
  end

  def init(alloc) do
    tree = [worker(alloc, [], restart: :temporary)]
    supervise(tree, strategy: :simple_one_for_one)
  end
end
