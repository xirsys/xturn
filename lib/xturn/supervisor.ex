defmodule XTurn.Supervisor do
  use Supervisor
  require Logger

  alias XTurn.{TcpClient, PeerSupervisor}
  alias XTurn.Udp.{Listener, ClientSupervisor}

  @buf_size 1024 * 1024 * 16
  @tcp_opts [
    reuseaddr: true,
    keepalive: true,
    backlog: 30,
    active: false,
    buffer: @buf_size,
    recbuf: @buf_size,
    sndbuf: @buf_size
  ]

  def start_link(listen, cb) do
    Supervisor.start_link(__MODULE__, [listen, cb], name: __MODULE__)
  end

  def init([listen, cb]) do
    children =
      listen
      |> Enum.map(fn data ->
        start_listener(data, cb)
      end)
      |> Enum.reject(&is_nil/1)

    Supervisor.init(
      [
        {PartitionSupervisor, child_spec: DynamicSupervisor, name: PeerSupervisor},
        {PartitionSupervisor, child_spec: DynamicSupervisor, name: ClientSupervisor}
      ] ++ children,
      strategy: :one_for_one
    )
  end

  defp terminate(reason, state) do
    state
  end

  defp start_listener({:tcp = type, ipStr, port}, cb) do
    try do
      {:ok, ip} = :inet_parse.address(ipStr)

      {:ok, _} =
        :ranch.start_listener(
          id(type, port),
          :ranch_tcp,
          %{socket_opts: [port: port] ++ @tcp_opts},
          TcpClient,
          []
        )

      nil
    rescue
      e ->
        nil
    end
  end

  defp start_listener({:udp = type, ipStr, port}, cb) do
    try do
      {:ok, ip} = :inet_parse.address(ipStr)
      name = id(type, port) |> String.to_atom()
      worker(Listener, [name, ip, port], id: name)
    rescue
      e ->
        nil
    end
  end

  defp id(type, port, secure \\ ""), do: "#{type}_listener_#{secure}_#{port}"
end
