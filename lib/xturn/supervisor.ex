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
