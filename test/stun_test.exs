defmodule StunTest do
  # bring in the test functionality
  use ExUnit.Case
  require Logger

  alias Xirsys.Stun
  alias Xirsys.Turn.{Conn, Commands}
  alias Xirsys.Sockets.Socket

  @conn %Conn{
    client_ip: {127, 0, 0, 2},
    client_port: 8881,
    server_ip: {127, 0, 0, 3},
    server_port: 8882
  }
  @stun %Stun{
    class: :request,
    method: :binding,
    transactionid: 123_456_789_012
  }

  setup do
    {:ok, stun: Stun.encode(@stun)}
  end

  test "valid stun packet format", %{stun: stun} do
    # is at least 16 bits and starts with 00 bits
    assert valid_stun(stun)
  end

  test "returns valid response", %{stun: stun} do
    conn = Commands.process_message(%Conn{@conn | message: stun})

    assert conn.response.class == :success,
           "STUN request should be valid"

    assert Map.get(conn.response.attrs || %{}, :xor_mapped_address) ==
             {@conn.client_ip, @conn.client_port},
           "must return a xor-mapped-address"

    assert Map.get(conn.response.attrs || %{}, :mapped_address) ==
             {@conn.client_ip, @conn.client_port},
           "must return a mapped-address"

    assert Map.get(conn.response.attrs || %{}, :response_origin) ==
             {Socket.server_ip(), @conn.server_port},
           "must return a response-origin"
  end

  defp valid_stun(<<0::2, _::14, _rest::binary>>) do
    true
  end

  defp valid_stun(_) do
    false
  end
end
