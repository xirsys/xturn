### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
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

defmodule Xirsys.XTurn.Actions.Authenticates do
  @doc """
  Authenticates the calling user. Any authentication requests
  without integrity and user credentials can be allowed
  via config.
  """
  require Logger
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  @auth Application.get_env(:xturn, :authentication)

  def process(
        %Conn{force_auth: force_auth, message: message, decoded_message: %Stun{attrs: attrs}} =
          conn
      ) do
    with true <-
           Map.has_key?(attrs, :username) and Map.has_key?(attrs, :realm) and
             (@auth.required or force_auth),
         %Stun{} = turn_dec <-
           process_integrity(message, Map.get(attrs, :username), Map.get(attrs, :realm)) do
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
  defp process_integrity(msg, username, realm) do
    Logger.info("Checking USERNAME #{inspect(username)}")

    with ^username <- @auth.username,
         key <- username <> ":" <> realm <> ":" <> @auth.credential,
         _ <- Logger.info("KEY = #{inspect(key)}"),
         {:ok, turn} <- Stun.decode(msg, key) do
      %Stun{turn | key: key}
    else
      e ->
        Logger.info("Integrity process failed: #{inspect(e)}")
        false
    end
  end
end
