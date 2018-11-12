defmodule ClientTest do
  # bring in the test functionality
  use ExUnit.Case
  # import ExUnit.CaptureIO # And allow us to capture stuff sent to stdout

  # alias Xirsys.Turn.Allocate.Client, as: C

  # test "milliseconds_left" do
  #   now = :calendar.local_time()
  #   start_time = :calendar.datetime_to_gregorian_seconds(now)
  #   assert C.milliseconds_left(start_time, 10) == 10_000
  #   receive do
  #     R -> R
  #   after
  #     5000 -> assert C.milliseconds_left(start_time, 10) == 5_000
  #   end
  # end
end
