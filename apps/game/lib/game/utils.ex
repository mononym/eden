defmodule Exmud.Game.Utils do
  @moduledoc false

  import Exmud.Common.Utils

  def game_cfg(key), do: cfg(:game, key)
end
