defmodule SockImplTest do
  # bring in the test functionality
  use ExUnit.Case
  require Logger

  alias XMediaLib.Stun
  alias Xirsys.XTurn.SockImpl

  test "processes complete binary payload" do
    {:ok, file} = File.read("test/support/raw-ulaw.raw")

    list =
      file
      |> chunk()
      |> Enum.map(fn c ->
        Stun.encode(%XMediaLib.Stun{
          attrs: %{
            data: c,
            xor_peer_address: {{185, 136, 233, 160}, 58299}
          },
          class: :indication,
          method: :send,
          transactionid: 36_001_151_279_674_394_614_990_592_304
        })
      end)

    mapped =
      list
      |> Enum.join("")

    processed =
      mapped
      |> process()

    resp = processed
      |> Enum.join("")

    assert String.length(resp) == String.length(file)
    assert resp == file
  end

  defp process(bin) when is_binary(bin) do
    process({[], bin})
  end

  defp process({handled, <<>>}), do: handled

  defp process({handled, bin}) do
    with {processed, nbin} when not is_nil(processed) <- SockImpl.process_buffer(bin),
         {:ok, %XMediaLib.Stun{attrs: %{
             data: data,
             xor_peer_address: {{185, 136, 233, 160}, 58299}
           },
           class: :indication,
           method: :send,
           transactionid: 36_001_151_279_674_394_614_990_592_304
         }} <- Stun.decode(processed) do
      process({[data | handled], nbin})
    end
  end

  defp chunk(data, list \\ [])
  defp chunk(<<c::binary-size(100), rest::binary()>>, list), do: chunk(rest, [c | list])
  defp chunk(<<>>, list), do: list
  defp chunk(c, list), do: [c | list]
end
