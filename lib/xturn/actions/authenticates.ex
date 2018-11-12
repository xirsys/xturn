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
