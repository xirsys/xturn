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

defmodule Xirsys.XTurn.Allocate.Store do
  @moduledoc """

  """
  # import Exts
  require Logger

  @vsn "0"

  alias Xirsys.XTurn.Tuple5, as: T5

  def init(),
    do: Exts.new(__MODULE__, access: :public)

  def insert(tid, pid, {{_, _, _, _}, _port} = relay, %T5{} = tuple5, socket, perms),
    do: Exts.write(__MODULE__, {tid, {pid, relay, T5.to_map(tuple5), socket, perms}})

  def lookup(tid) when is_binary(tid) do
    case Exts.read(__MODULE__, tid) do
      [{_tid, {pid, _, _, socket, perms}}] -> {:ok, pid, socket, perms}
      [] -> {:error, :not_found}
    end
  end

  def lookup([{:ca, _}, {:cp, _}, {:sa, _}, {:sp, _}, {:proto, _}] = tuple5),
    do: match({:_, {:"$1", :"$2", tuple5, :"$3", :"$4"}})

  def lookup({{i1, i2, i3, i4}, _port} = relay_address)
      when is_integer(i1) and i1 < 256 and is_integer(i2) and i2 < 256 and is_integer(i3) and
             i3 < 256 and is_integer(i4) and i4 < 256,
      do: match({:_, {:"$1", relay_address, :"$2", :"$3", :"$4"}})

  def exists(criteria) do
    case lookup(criteria) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def delete(key),
    do: :ets.delete(__MODULE__, key)

  defp match(criteria) do
    lookup = Exts.match(__MODULE__, criteria)
    maybe_values(lookup)
  end

  defp maybe_values(%{values: [client]}) when is_list(client),
    do: {:ok, client}

  defp maybe_values(_),
    do: {:error, :not_found}
end
