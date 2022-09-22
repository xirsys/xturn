### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Jahred Love and Xirsys LLC <experts@xirsys.com>
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
  use Agent

  @moduledoc """
  Simple caching module with TTL, used by the XTurn TURN server project.
  """

  ###########################
  # MESSY - NEEDS IMPROVING
  ###########################

  @doc """
  Create a cache context.
  """
  @spec init(integer()) :: {:ok, pid()}
  def init(),
    do: Agent.start_link(fn -> {%{}, 300_000, nil} end)

  @doc """
  Create a cache context with specified TTL.
  """
  def init(lifetime),
    do: Agent.start_link(fn -> {%{}, lifetime, nil} end)

  @doc """
  Create a cache context with specified TTL and onTTL callback.
  """
  def init(lifetime, callback),
    do: Agent.start_link(fn -> {%{}, lifetime, callback} end)

  @doc """
  Add a value by key.

  Returns `:ok`

  ## Examples

      iex> ctx = Xirsys.XTurn.Cache.Store.init()
      {:ok, pid()}
      iex> Xirsys.XTurn.Cache.Store.append(ctx, {"key", "value"})
      :ok
  """
  @spec append(pid(), {term(), term()}) :: :ok | no_return
  def append(agent, {id, ndata}) do
    {store, lt, _cb} = get_state(agent)

    new_store = create_element(agent, lt, id, store, ndata)

    update_store(agent, new_store)
    :ok
  end

  @doc """
  Add multiple key / value's.

  Returns `:ok`

  ## Examples

      iex> ctx = Xirsys.XTurn.Cache.Store.init()
      {:ok, pid()}
      iex> Xirsys.XTurn.Cache.Store.append_items_to_store(ctx, [{"key", "value"}, {"key2", "value2"}])
      :ok
  """
  @spec append_many(pid(), list({term(), term()})) :: :ok | no_return
  def append_many(_agent, []),
    do: :ok

  def append_many(agent, [elem | tail] = _elems) do
    append(agent, elem)
    append_many(agent, tail)
  end

  @doc """
  Removes a key and its value.

  Returns `:ok`

  ## Examples

      iex> ctx = Xirsys.XTurn.Cache.Store.init()
      {:ok, pid()}
      iex> Xirsys.XTurn.Cache.Store.append_item_to_store(ctx, {"key", "value"})
      :ok
      iex> Xirsys.XTurn.Cache.Store.remove_item_from_store(ctx, "key")
      :ok
  """
  @spec remove(pid(), term()) :: :ok | no_return
  def remove(agent, id) do
    {store, _, _} = get_state(agent)
    new_store = Map.delete(store, id)
    update_store(agent, new_store)
    :ok
  end

  @doc """
  Returns true if a key exists; otherwise false.
  """
  @spec has_key?(pid(), term()) :: boolean()
  def has_key?(agent, id) do
    {store, _, _} = get_state(agent)
    Map.has_key?(store, id)
  end

  @doc """
  Returns all the keys in the cache.
  """
  @spec keys(pid()) :: list()
  def keys(agent) do
    {store, _, _} = get_state(agent)
    Map.keys(store)
  end

  @doc """
  Returns the number of keys in the cache.
  """
  @spec item_count(pid()) :: integer()
  def item_count(agent) do
    {store, _, _} = get_state(agent)
    Kernel.map_size(store)
  end

  @doc """
  Destroys the cache (cleanup).
  """
  @spec terminate(pid()) :: :ok
  def terminate(agent),
    do: Agent.stop(agent)

  @doc """
  Returns the agent state as a raw map.
  """
  @spec get_state(pid()) :: map()
  def get_state(agent),
    do: Agent.get(agent, fn {s, l, c} -> {s, l, c} end)

  @doc """
  Not to be called directly. Used by the cache to timeout keys.
  """
  def timer_callback(agent, id) do
    {store, _, cb} = get_state(agent)
    Logger.info("Deleting item #{inspect(id)}")
    new_store = Map.delete(store, id)
    update_store(agent, new_store)
    if cb != nil, do: apply(cb, [id])
    :ok
  end

  @doc """
  Returns the value of a key in an erlang success tuple.
  """
  @spec fetch(pid(), term()) :: {:ok, term()} | :error
  def fetch(agent, id) do
    {store, _, _} = get_state(agent)

    case Map.fetch(store, id) do
      {:ok, {_t, d}} ->
        {:ok, d}

      _ ->
        :error
    end
  end

  @doc """
  Returns the value of a key or nil if not exists.
  """
  @spec fetch!(pid(), term()) :: term() | nil
  def fetch!(agent, id) do
    {store, _, _} = get_state(agent)

    case Map.fetch(store, id) do
      {:ok, {_t, d}} ->
        d

      _ ->
        nil
    end
  end

  defp create_element(agent, lt, id, store, ndata) do
    case start_item_timer(agent, lt, id) do
      {:ok, tref} ->
        Map.put(store, id, {tref, fetch_from_store(store, id, ndata)})

      _ ->
        Map.put(store, id, {nil, ndata})
    end
  end

  defp fetch_from_store(store, id, ndata) do
    case Map.has_key?(store, id) do
      true ->
        {:ok, {t, d}} = Map.fetch(store, id)
        :timer.cancel(t)
        if ndata, do: ndata, else: d

      _ ->
        ndata
    end
  end

  defp start_item_timer(agent, lt, id),
    do: :timer.apply_interval(lt, __MODULE__, :timer_callback, [agent, id])

  defp update_store(agent, store),
    do: Agent.update(agent, fn {_, l, c} -> {store, l, c} end)
end
