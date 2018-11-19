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

defmodule Xirsys.Sockets.Response do
  @moduledoc """
  TURN connection object
  """

  @vsn "0"

  defstruct class: nil,
            attrs: nil,
            err_no: nil,
            message: nil
end
