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

defmodule Xirsys.XTurn.Supervisor do
  use Supervisor

  alias Xirsys.XTurn.{Server, Allocate, Auth}
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
        worker(Auth.Supervisor, []),
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
