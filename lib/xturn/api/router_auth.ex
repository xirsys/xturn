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

defmodule Xirsys.API.Router.Auth do
  use Maru.Router

  namespace :auth do
    desc("Adds a user to the user list")

    params do
      optional(:username, type: String)
      optional(:password, type: String)
      # This is used for analytics purposes. Maybe a room name or project name
      optional(:namespace, type: String)
      # id of the account creating the user. Useful for analytics and billing
      optional(:peer_id, type: String)
    end

    post do
      if not params[:username] or not params[:password] do
        {:ok, u, p} =
          Xirsys.XTurn.Auth.Client.create_user(
            params[:namespace] || "",
            params[:peer_id] || ""
          )

        json(conn, %{status: :ok, username: u, password: p})
      else
        {:ok, u, p} =
          Xirsys.XTurn.Auth.Client.add_user(
            params[:username],
            params[:password],
            params[:namespace] || "",
            params[:peer_id] || ""
          )

        json(conn, %{status: :ok, username: u, password: p})
      end
    end
  end
end
