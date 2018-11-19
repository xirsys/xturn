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

defmodule Xirsys.API.Router.Allocation do
  use Maru.Router

  namespace :allocation do
    desc("returns the current number of allocations on the server")

    get do
      {:ok, workers} = Xirsys.XTurn.Allocate.Client.count()
      json(conn, %{status: :ok, count: workers})
    end
  end
end
