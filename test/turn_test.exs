defmodule TurnTest do
  # bring in the test functionality
  use ExUnit.Case, async: false
  require Logger

  alias Xirsys.Stun
  alias Xirsys.Turn.{Conn, Commands}
  alias Xirsys.Turn.Auth.Client, as: Auth
  alias Xirsys.Turn.Allocate.Client, as: AllocateClient
  alias Xirsys.Sockets.Socket

  @conn %Conn{
    client_ip: {127, 0, 0, 2},
    client_port: 8881,
    server_ip: {127, 0, 0, 1},
    server_port: 8882
  }
  @alternate_ip {127, 0, 0, 3}
  @allocation %Stun{
    class: :request,
    method: :allocate,
    transactionid: 123_456_789_012,
    attrs: %{
      requested_transport: <<17, 0, 0, 0>>
    }
  }
  @realm "xirsys.com"
  @username "some_user"
  @password "some_pass"

  test "allocates without authentication" do
    # store the current number of allocation workers
    {:ok, orig_workers} = AllocateClient.count()

    # create encoded STUN packet
    stun = Stun.encode(@allocation)
    # process
    conn = Commands.process_message(%Conn{@conn | message: stun})

    # response should be valid and contain reflexive IP and Port
    assert conn.response.class == :success,
           "STUN request was successful"

    assert Map.get(conn.response.attrs, :xor_mapped_address) ==
             {@conn.client_ip, @conn.client_port},
           "response has valid xor-mapped-address"

    assert Map.has_key?(conn.response.attrs, :xor_relayed_address),
           "response has valid xor-relayed-address"

    # check an integer base port id is attributed
    ip = Socket.server_ip()
    {^ip, port} = Map.get(conn.response.attrs, :xor_relayed_address)

    assert is_integer(port),
           "assigned port is an integer"

    assert Map.get(conn.response.attrs, :lifetime) == <<600::32>>,
           "response contains a five minute TTL"

    # assert that we now have one more allocation client
    {:ok, workers} = AllocateClient.count()

    assert workers == orig_workers + 1,
           "an allocation worker has been created"
  end

  test "allocates with authentication" do
    # store the current number of allocation workers
    {:ok, orig_workers} = AllocateClient.count()

    # as we're authenticating, apply user and pass
    attrs = Map.merge(@allocation.attrs, %{username: @username, password: @password})

    # create encoded STUN packet
    stun = Stun.encode(%Stun{@allocation | attrs: attrs})

    conn =
      Commands.process_message(%Conn{
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

    assert realm == @realm,
           "realm should be valid value for this TURN server"

    # assign the realm to the attributes for the next pass
    attrs = Map.merge(attrs, %{realm: realm})

    # re-encode updated data
    stun = Stun.encode(%Stun{@allocation | attrs: attrs})
    # now we should add our user to the manifest, so it passes the lookup
    Auth.add_user(@username, @password, "/", "server")

    # second pass
    conn =
      Commands.process_message(%Conn{
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
    ip = Socket.server_ip()
    {^ip, port} = Map.get(conn.response.attrs, :xor_relayed_address)

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
