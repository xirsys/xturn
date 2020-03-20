### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2020 Jahred Love and Xirsys LLC <experts@xirsys.com>
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
