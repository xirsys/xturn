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
