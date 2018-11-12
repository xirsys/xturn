### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### Redistribution and use in source and binary forms, with or without modification,
### are permitted provided that the following conditions are met:
###
### * Redistributions of source code must retain the above copyright notice, this
### list of conditions and the following disclaimer.
### * Redistributions in binary form must reproduce the above copyright notice,
### this list of conditions and the following disclaimer in the documentation
### and/or other materials provided with the distribution.
### * Neither the name of the authors nor the names of its contributors
### may be used to endorse or promote products derived from this software
### without specific prior written permission.
###
### THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
### EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
### WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
### DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
### DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
### (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
### LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
### ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
### (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
### SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
