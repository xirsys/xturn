### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache License, Version 2.0.
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule Xirsys.XTurn.Timing do
  def local_time(),
    do: :calendar.local_time()

  def now(),
    do:
      :calendar.local_time()
      |> :calendar.datetime_to_gregorian_seconds()

  def milliseconds_left(start_time, lifetime),
    do: seconds_left(start_time, lifetime) * 1_000

  def milliseconds_left(%{refresh_time: time, lifetime: life} = _state),
    do: seconds_left(time, life) * 1_000

  defp seconds_left(start_time, lifetime) do
    time_elapsed = now() - start_time

    case lifetime - time_elapsed do
      time when time <= 0 -> 0
      time -> time
    end
  end
end
