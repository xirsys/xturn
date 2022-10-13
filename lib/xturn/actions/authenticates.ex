### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2022 Jahred Love and Xirsys LLC <experts@xirsys.com>
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

defmodule XTurn.Actions.Authenticates do
  @doc """
  Authenticates the calling user. Any authentication requests
  without integrity and user credentials can be allowed
  via config.
  """
  require Logger
  alias XTurn.{Stun, Conn, Utils}

  @nonce Application.get_env(:xturn, :nonce)
  @realm Application.get_env(:xturn, :realm)

  def process(%Conn{halt: true} = conn), do: conn

  def process(
        %Conn{
          pkt: pkt,
          turn: %Stun{method: method, attrs: %{username: username}, transactionid: tid} = turn,
          state: %{username: username, key: hkey} = state
        } = conn
      ) when not is_nil(username) and not is_nil(hkey) do
    %Conn{conn | turn: %Stun{turn | key: hkey}}
  end

  def process(
        %Conn{
          pkt: pkt,
          turn: %Stun{method: method, attrs: attrs, transactionid: tid},
          state: state
        } = conn
      ) do
    Logger.debug("authenticating, #{inspect attrs}")
    # Do the attributes contain username and realm?
    with {realm, :realm} <- {Application.get_env(:xturn, :realm), :realm},
         {username, :username} when not is_nil(username) <- {Map.get(attrs, :username), :username},
         # Re-decode STUN packet using integrity check
         {%Stun{key: hkey} = turn_dec, :stun} <- {process_integrity(pkt, username, realm), :stun} do
      # Update and return connection object
      %Conn{conn | turn: turn_dec, state: Map.put(state, :username, username) |> Map.put(:key, hkey)}
    else
      e ->
        Logger.debug("#{inspect e}")
        # Something went wrong. Flag unauthorized
        nattrs = Map.put(attrs, :error_code, {401, "Unauthorized"})
        nattrs = Map.put(nattrs, :nonce, @nonce)
        nattrs = Map.put(nattrs, :realm, @realm)

        %Conn{
          conn
          | halt: true,
            resp: %Stun{class: :error, method: method, transactionid: tid, attrs: nattrs}
        }
    end
  end

  # Re-processes the STUN message if integrity and username tags are present.
  # This forces TURN authentication requirements.

  ### TODO: Correctly implement custom XirSys authentication to TURN spec [RFC5766]
  defp process_integrity(pkt, username, realm) do
    Logger.info("Checking USERNAME #{inspect(username)}")

    with secret <- Application.get_env(:xturn, :turn_key),
         [ttl, un] <- String.split(username, ":"),
         ts <- Utils.timestamp(),
         {int_val, ""} when int_val > ts <- Integer.parse(ttl),
         credential <- hmac_fun(:sha, secret, username) |> Base.encode64(),
         key <- username <> ":" <> realm <> ":" <> credential,
         hkey <- :crypto.hash(:md5, key),
         {:ok, turn} <- Stun.decode(pkt, hkey) do
      Logger.debug("credential: #{inspect credential}")
      %Stun{turn | key: hkey}
    else
      e ->
        Logger.warn("Integrity process failed: #{inspect(e)}")
        nil
    end
  end

  if System.otp_release() >= "22" do
    defp hmac_fun(digest, key, message), do: :crypto.mac(:hmac, digest, key, message)
  else
    defp hmac_fun(digest, key, message), do: :crypto.hmac(digest, key, message)
  end
end
