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

defmodule Xirsys.API do
  use Maru.Router

  before do
    plug(
      Plug.Parsers,
      pass: ["*/*"],
      json_decoder: Poison,
      parsers: [:urlencoded, :json, :multipart]
    )
  end

  mount(Xirsys.API.Router.Auth)
  mount(Xirsys.API.Router.Allocation)

  rescue_from :all, as: e do
    IO.inspect(e)

    conn
    |> put_status(500)
    |> text("Server Error")
  end
end
