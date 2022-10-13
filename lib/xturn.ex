defmodule XTurn do
  @moduledoc """
  Application stub, used to parent TURN connections supervisor
  """
  use Application
  require Logger

  def start(_type, args) do
    if is_nil(Application.get_env(:xturn, :server_ip)) do
      Application.put_env(:xturn, :server_ip, server_ip())
    end

    XTurn.Supervisor.start_link(
      Application.get_env(:xturn, :listen),
      XTurn.SockImpl
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
