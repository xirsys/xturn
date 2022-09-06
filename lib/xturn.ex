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

defmodule Xirsys.XTurn do
  @moduledoc """
  Application stub, used to parent TURN connections supervisor
  """
  use Application
  require Logger

  def start(_type, args) do
    Xirsys.XTurn.Allocate.Store.init()
    Xirsys.XTurn.Channels.Store.init()

    if is_nil(Application.get_env(:xturn, :server_ip)) do
      Application.put_env(:xturn, :server_ip, server_ip())
    end

    Logger.info("#{inspect(Application.get_env(:xturn, :server_ip))}")

    Xirsys.XTurn.Supervisor.start_link(
      Application.get_env(:xturn, :listen),
      Xirsys.XTurn.SockImpl
    )
  end

  def main(argv) do
    main(argv)
  end

  defp server_ip() do
    case System.get_env("XTURN_SERVER_IP") do
      ip when is_binary(ip) and ip != "" ->
        case String.to_charlist(ip) |> :inet.parse_address() do
          {:ok, address} -> address
          _ -> {0, 0, 0, 0}
        end

      _ ->
        {0, 0, 0, 0}
    end
  end

  defp maybe_ip_flag(listen_config) do
    case System.get_env("XTURN_SERVER_IP") do
      ip when is_binary(ip) and ip != "" ->
        process_ip(listen_config, ip)

      e ->
        listen_config
    end
  end

  defp process_ip(listen_config, ip) do
    case String.to_charlist(ip) |> :inet.parse_address() do
      {:ok, address} ->
        Logger.info("IP detected: #{ip}")

        Enum.map(listen_config, fn
          {type, _, port} ->
            {type, String.to_charlist(ip), port}

          {type, _, port, tls} ->
            {type, String.to_charlist(ip), port, tls}
        end)

      _ ->
        Logger.info("IP not valid")
        listen_config
    end
  end
end
