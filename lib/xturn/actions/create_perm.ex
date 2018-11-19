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

defmodule Xirsys.XTurn.Actions.CreatePerm do
  @doc """
  Assigns a permission for a peer on a given client allocation
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("creating a permission #{inspect(conn.decoded_message)}")
    tuple5 = Tuple5.to_map(Tuple5.create(conn, :_))

    with {_ip, _port} = p <- Map.get(attrs, :xor_peer_address),
         {:ok, [client, _peer_address, _, _]} <- Store.lookup(tuple5) do
      Logger.debug("createperm #{inspect(client)}, #{inspect(p)}")
      AllocateClient.add_permissions(client, p)
      Conn.response(conn, :success)
    else
      {:error, _} ->
        Logger.debug("client does not exist #{inspect(tuple5)} (createperm)")
        Conn.response(conn, 400, "Bad Request")

      _ ->
        Logger.debug("no permissions sent")
        Conn.response(conn, 400, "Bad Request")
    end
  end
end
