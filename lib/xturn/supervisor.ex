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

defmodule Xirsys.XTurn.Supervisor do
  use Supervisor

  alias Xirsys.XTurn.{Server, Allocate}
  alias Xirsys.Sockets.Listener.{TCP, UDP}
  alias Xirsys.Sockets.SockSupervisor

  def start_link(listen, cb) do
    Supervisor.start_link(__MODULE__, [listen, cb])
  end

  def init([list, cb]) do
    listen = list

    children =
      listen
      |> Enum.map(fn data ->
        start_listener(data, cb)
      end)

    supervise(
      [
        worker(Server, []),
        worker(Allocate.Supervisor, [Allocate.Client]),
        worker(SockSupervisor, [])
      ] ++ children,
      strategy: :one_for_one
    )
  end

  defp start_listener({type, ipStr, port}, cb) do
    {:ok, ip} = :inet_parse.address(ipStr)
    worker(listener(type), [cb, ip, port, false], id: id(type, port))
  end

  defp start_listener({type, ipStr, port, secure}, cb) do
    {:ok, ip} = :inet_parse.address(ipStr)
    worker(listener(type), [cb, ip, port, secure == :secure], id: id(type, port, secure))
  end

  defp listener(:tcp), do: TCP
  defp listener(:udp), do: UDP
  defp id(type, port, secure \\ ""), do: "#{type}_listener_#{secure}_#{port}"
end
