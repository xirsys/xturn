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

defmodule Xirsys.XTurn.Cache.Store do
  @vsn "0"
  require Logger

  ###########################
  # MESSY - NEEDS IMPROVING
  ###########################

  def init(),
    do: Agent.start_link(fn -> {%{}, 300_000, nil} end)

  def init(lifetime),
    do: Agent.start_link(fn -> {%{}, lifetime, nil} end)

  def init(lifetime, callback),
    do: Agent.start_link(fn -> {%{}, lifetime, callback} end)

  def append_item_to_store(agent, {id, ndata}) do
    {store, lt, _cb} = get_state(agent)

    new_store =
      case start_item_timer(agent, lt, id) do
        {:ok, tref} ->
          data =
            case Map.has_key?(store, id) do
              true ->
                {:ok, {t, d}} = Map.fetch(store, id)
                :timer.cancel(t)
                if ndata, do: ndata, else: d

              _ ->
                ndata
            end

          Map.put(store, id, {tref, data})

        _ ->
          Map.put(store, id, {nil, ndata})
      end

    update_store(agent, new_store)
    :ok
  end

  def append_items_to_store(_agent, []),
    do: :ok

  def append_items_to_store(agent, [elem | tail] = _elems) do
    append_item_to_store(agent, elem)
    append_items_to_store(agent, tail)
  end

  def remove_item_from_store(agent, id) do
    {store, _, _} = get_state(agent)
    new_store = Map.delete(store, id)
    update_store(agent, new_store)
    :ok
  end

  def has_key?(agent, id) do
    {store, _, _} = get_state(agent)
    Map.has_key?(store, id)
  end

  def keys(agent) do
    {store, _, _} = get_state(agent)
    Map.keys(store)
  end

  def get_item_count(agent) do
    {store, _, _} = get_state(agent)
    Kernel.map_size(store)
  end

  def terminate(agent),
    do: Agent.stop(agent)

  def get_state(agent),
    do: Agent.get(agent, fn {s, l, c} -> {s, l, c} end)

  def timer_callback(agent, id) do
    {store, _, cb} = get_state(agent)
    Logger.info("Deleting item #{inspect(id)}")
    new_store = Map.delete(store, id)
    update_store(agent, new_store)
    if cb != nil, do: apply(cb, [id])
    :ok
  end

  def fetch(agent, id) do
    {store, _, _} = get_state(agent)

    case Map.fetch(store, id) do
      {:ok, {_t, d}} ->
        {:ok, d}

      _ ->
        :error
    end
  end

  defp start_item_timer(agent, lt, id),
    do: :timer.apply_interval(lt, __MODULE__, :timer_callback, [agent, id])

  defp update_store(agent, store),
    do: Agent.update(agent, fn {_, l, c} -> {store, l, c} end)
end
