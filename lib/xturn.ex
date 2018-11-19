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

defmodule Xirsys.XTurn do
  @moduledoc """
  Application stub, used to parent TURN connections supervisor
  """
  use Application

  def start(_type, _args) do
    Xirsys.XTurn.Allocate.Store.init()
    Xirsys.XTurn.Channels.Store.init()

    Xirsys.XTurn.Supervisor.start_link(
      Application.get_env(:xturn, :listen),
      Xirsys.XTurn.Commands
    )
  end

  def main(argv) do
    main(argv)
  end
end
