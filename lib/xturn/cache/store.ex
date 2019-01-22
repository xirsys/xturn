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
