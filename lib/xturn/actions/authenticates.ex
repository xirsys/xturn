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

defmodule Xirsys.XTurn.Actions.Authenticates do
  @doc """
  Authenticates the calling user. Any authentication requests
  without integrity and user credentials can be allowed
  via config.
  """
  require Logger
  alias Xirsys.XTurn.Auth.Client, as: AuthClient
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  @auth Application.get_env(:xturn, :authentication)
  @realm Application.get_env(:xturn, :realm)

  def process(
        %Conn{force_auth: force_auth, message: message, decoded_message: %Stun{attrs: attrs}} =
          conn
      ) do
    with true <- Map.has_key?(attrs, :username) and (@auth.required or force_auth),
         %Stun{} = turn_dec <- process_integrity(message, Map.get(attrs, :username)) do
      %Conn{conn | decoded_message: turn_dec}
    else
      _ ->
        if @auth.required or force_auth,
          do: Conn.response(conn, 401, "Unauthorized"),
          else: conn
    end
  end

  # Re-processes the STUN message if integrity and username tags are present.
  # This forces TURN authentication requirements.

  ### TODO: Correctly implement custom XirSys authentication to TURN spec [RFC5766]
  defp process_integrity(msg, username) do
    Logger.info("Checking USERNAME #{inspect(username)}")

    with {:ok, pw, ns, peer_id} <- AuthClient.get_details(username),
         key <- username <> ":" <> @realm <> ":" <> pw,
         _ <- Logger.info("KEY = #{inspect(key)}"),
         {:ok, turn} <- Stun.decode(msg, key) do
      %Stun{turn | key: key, ns: ns, peer_id: peer_id}
    else
      e ->
        Logger.info("Integrity process failed: #{inspect(e)}")
        false
    end
  end
end
