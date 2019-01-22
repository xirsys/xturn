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
