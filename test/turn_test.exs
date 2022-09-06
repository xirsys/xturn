defmodule TurnTest do
  # bring in the test functionality
  use ExUnit.Case, async: false
  require Logger

  alias Xirsys.Sockets.Conn
  alias Xirsys.XTurn.{Stun, Pipeline}
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.Sockets.Socket

  @conn %Conn{
    client_ip: {127, 0, 0, 2},
    client_port: 8881,
    server_ip: {127, 0, 0, 1},
    server_port: 8882
  }
  @alternate_ip {127, 0, 0, 3}
  @key "guest:xturn.me:guest"
  @hkey <<167, 133, 227, 10, 84, 29, 235, 132, 185, 220, 181, 166, 131, 75, 32, 16>>
  @realm "xturn.me"
  @username "guest"
  @password "guest"
  @allocation %Stun{
    class: :request,
    method: :allocate,
    transactionid: 123_456_789_012,
    key: @hkey,
    attrs: %{
      requested_transport: <<17, 0, 0, 0>>
    }
  }

  test "allocates without authentication" do
    Application.put_env(:xturn, :authentication, %{required: false, username: "guest", credential: "guest"})
    Application.put_env(:xturn, :realm, "xturn.me")

    # store the current number of allocation workers
    {:ok, orig_workers} = AllocateClient.count()

    # create encoded STUN packet
    stun = Stun.encode(@allocation)
    # process
    conn = Pipeline.process_message(%Conn{@conn | message: stun, force_auth: false})

    # response should be valid and contain reflexive IP and Port

    assert conn.response.class == :success,
           "STUN request was unsuccessful"

    assert Map.get(conn.response.attrs, :xor_mapped_address) ==
             {@conn.client_ip, @conn.client_port},
           "response does not have valid xor-mapped-address"

    assert Map.has_key?(conn.response.attrs, :xor_relayed_address),
           "response does not have valid xor-relayed-address"

    # check an integer base port id is attributed
    {server_ip, port} = Map.get(conn.response.attrs, :xor_relayed_address)

    assert server_ip == @conn.server_ip

    assert is_integer(port),
           "assigned port is not an integer"

    assert Map.get(conn.response.attrs, :lifetime) == <<600::32>>,
           "response does not contain a five minute TTL"

    # assert that we now have one more allocation client
    {:ok, workers} = AllocateClient.count()

    assert workers == orig_workers + 1,
           "an allocation worker has not been created"
  end

  test "allocates with authentication" do
    Application.put_env(:xturn, :authentication, %{required: true, username: "guest", credential: "guest"})
    Application.put_env(:xturn, :realm, "xturn.me")

    # store the current number of allocation workers
    {:ok, orig_workers} = AllocateClient.count()

    # create encoded STUN packet
    stun = Stun.encode(@allocation)

    conn =
      Pipeline.process_message(%Conn{
        @conn
        | message: stun,
          client_ip: @alternate_ip,
          force_auth: true
      })

    # the first request should fail, but we need the returned realm to authenticate
    refute conn.response.class == :success,
           "first request must not succeed"

    assert Map.has_key?(conn.decoded_message.attrs || %{}, :realm),
           "failed authentication should return a realm"

    realm = Map.get(conn.decoded_message.attrs, :realm)

    IO.inspect realm

    assert realm == @realm,
           "realm should be valid value for this TURN server"

    # as we're authenticating, apply user and pass
    attrs = Map.merge(@allocation.attrs, %{realm: realm, username: @username, password: @password})

    # re-encode updated data
    stun = Stun.encode(%Stun{@allocation | attrs: attrs})

    # second pass
    conn =
      Pipeline.process_message(%Conn{
        @conn
        | message: stun,
          client_ip: @alternate_ip,
          force_auth: true
      })

    # this should now pass and have an established relay address / port
    assert conn.response.class == :success,
           "STUN request was successful"

    assert Map.get(conn.response.attrs, :xor_mapped_address) ==
             {@alternate_ip, @conn.client_port},
           "response has valid xor-mapped-address"

    assert Map.has_key?(conn.response.attrs, :xor_relayed_address),
           "response has valid xor-relayed-address"

    # validate an assigned port and that it's an integer
    {server_ip, port} = Map.get(conn.response.attrs, :xor_relayed_address)

    assert server_ip == @conn.server_ip

    assert is_integer(port),
           "assigned port is an integer"

    assert Map.get(conn.response.attrs, :lifetime) == <<600::32>>,
           "response contains a five minute TTL"

    # assert that we now have one more allocation client
    {:ok, workers} = AllocateClient.count()

    assert workers == orig_workers + 1,
           "an allocation worker has been created"
  end
end
