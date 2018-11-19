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

defmodule Xirsys.XTurn.Channels.Channel do
  @moduledoc """
  TURN channel state object
  """
  @vsn "0"
  defstruct id: nil,
            tuple5: nil,
            peer_address: nil,
            timer: nil
end
