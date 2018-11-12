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

defmodule Xirsys.XTurn.Auth.Client do
  @moduledoc """
  """
  use GenServer
  require Logger
  @vsn "0"

  @auth_lifetime 300_000

  #########################################################################################################################
  # Interface functions
  #########################################################################################################################

  def start_link(),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def create_user(ns),
    do: GenServer.call(__MODULE__, {:create_user, ns, ""})

  def create_user(ns, peer_id),
    do: GenServer.call(__MODULE__, {:create_user, ns, peer_id})

  def add_user(username, pass, ns, peer_id),
    do: GenServer.call(__MODULE__, {:add_user, username, pass, ns, peer_id})

  def get_pass(username),
    do: GenServer.call(__MODULE__, {:get_pass, username})

  def get_details(username),
    do: GenServer.call(__MODULE__, {:get_details, username})

  def get_count(),
    do: GenServer.call(__MODULE__, :get_count)

  def get_count(username, password),
    do: GenServer.call(__MODULE__, {:get_count, username, password})

  #########################################################################################################################
  # OTP functions
  #########################################################################################################################

  def init([]) do
    Logger.info("Initialising auth store")
    Xirsys.XTurn.Cache.Store.init(@auth_lifetime)
  end

  def handle_call({:create_user, ns, peer_id}, _from, state) do
    username = Xirsys.XTurn.Auth.UUID.utc_random()
    password = Xirsys.XTurn.Auth.UUID.utc_random()
    Xirsys.XTurn.Cache.Store.append_item_to_store(state, {username, {password, ns, peer_id}})
    {:reply, {:ok, username, password}, state}
  end

  def handle_call({:add_user, user, pass, ns, peer_id}, _from, state) do
    Xirsys.XTurn.Cache.Store.append_item_to_store(state, {user, {pass, ns, peer_id}})
    {:reply, {:ok, user, pass}, state}
  end

  def handle_call({:get_pass, "user"}, _from, state), do: {:reply, {:ok, "pass"}, state}

  def handle_call({:get_pass, username}, _from, state) do
    case Xirsys.XTurn.Cache.Store.fetch(state, username) do
      {:ok, {pass, _, _}} ->
        {:reply, {:ok, pass}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:get_details, "user"}, _from, state),
    do: {:reply, {:ok, "pass", nil, nil}, state}

  def handle_call({:get_details, username}, _from, state) do
    case Xirsys.XTurn.Cache.Store.fetch(state, username) do
      {:ok, {pass, ns, peer_id}} ->
        {:reply, {:ok, pass, ns, peer_id}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:get_count, _from, state) do
    {:reply, Xirsys.XTurn.Cache.Store.get_item_count(state), state}
  end
end
