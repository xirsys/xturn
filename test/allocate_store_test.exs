defmodule AllocateStoreTest do
  # bring in the test functionality
  use ExUnit.Case
  # import ExUnit.CaptureIO # And allow us to capture stuff sent to stdout

  alias Xirsys.Turn.Allocate.Store, as: S
  alias Xirsys.Turn.Tuple5

  @valid_address {{127, 0, 0, 2}, 8888}
  @invalid_address {{127, 0, 0, 3}, 8889}
  @ca {127, 0, 0, 1}
  @cp 80
  @sa {198, 162, 0, 1}
  @sp 54345

  def new_tuple5 do
    %Xirsys.Turn.Tuple5{
      client_address: @ca,
      client_port: @cp,
      server_address: @sa,
      server_port: @sp,
      protocol: :udp
    }
  end

  setup do
    tid = "12345"

    on_exit(fn ->
      S.delete(tid)
    end)

    pid = self()
    relay = @valid_address
    t5 = new_tuple5()
    S.insert(tid, pid, relay, t5, nil, nil)
    :ok
  end

  test "lookup entry by id" do
    assert S.lookup("12345") == {:ok, self(), nil, nil}
    assert S.lookup("12346") == {:error, :not_found}
  end

  test "lookup entry by relay address" do
    t5 = new_tuple5()
    assert S.lookup(@valid_address) == {:ok, [self(), Tuple5.to_map(t5), nil, nil]}
    assert S.lookup(@invalid_address) == {:error, :not_found}
  end

  test "lookup entry by 5 tuple" do
    t5 = new_tuple5()
    data = Tuple5.to_map(t5)
    assert S.lookup(data) == {:ok, [self(), @valid_address, nil, nil]}
    t5b = %{t5 | server_port: 54321}
    datb = Tuple5.to_map(t5b)
    assert S.lookup(datb) == {:error, :not_found}
  end
end
