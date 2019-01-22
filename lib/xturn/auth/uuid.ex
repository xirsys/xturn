### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
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

defmodule Xirsys.XTurn.Auth.UUID do
  @moduledoc """
  provides UUID generation for authentication
  """
  require Logger
  @vsn "0"

  def to_hex([]),
    do: []

  def to_hex(bin) when is_binary(bin),
    do: to_hex(:erlang.binary_to_list(bin))

  def to_hex([h | t]),
    do: [to_digit(div(h, 16)), to_digit(rem(h, 16)) | to_hex(t)]

  def to_digit(n) when n < 10 do
    [t] = '0'
    t + n
  end

  def to_digit(n) do
    [t] = 'a'
    t + n - 10
  end

  def random(),
    do: to_hex(:crypto.strong_rand_bytes(16))

  def utc_random() do
    now = {_, _, micro} = :erlang.timestamp()
    nowish = :calendar.now_to_universal_time(now)
    nowsecs = :calendar.datetime_to_gregorian_seconds(nowish)
    then = :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
    prefix = :io_lib.format("~14.16.0b", [(nowsecs - then) * 1_000_000 + micro])
    :erlang.list_to_binary(prefix ++ to_hex(:crypto.strong_rand_bytes(9)))
  end

  def new_prefix(),
    do: to_hex(:crypto.strong_rand_bytes(13))

  def inc(),
    do: :rand.uniform(0xFFE)
end
