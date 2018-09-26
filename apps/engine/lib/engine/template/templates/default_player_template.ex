defmodule Exmud.Engine.Template.DefaultPlayerTemplate do
  use Exmud.Engine.Template
  alias Exmud.Engine.Template.ComponentEntry

  @doc false
  def command_sets( _config ) do
    [

    ]
  end

  @doc false
  def components( config ) do
    [
      %ComponentEntry{
        callback_module: Exmud.Engine.Component.PlayerComponent,
        config: config
      }
    ]
  end

  @doc false
  def links( _config ) do
    []
  end

  @doc false
  def locks( _config ) do
    [

    ]
  end

  @doc false
  def scripts( _config ) do
    [

    ]
  end

  @doc false
  def tags( _config ) do
    [
      %Exmud.Engine.Template.TagEntry{
        category: engine_tag_category(),
        tag: player_tag()
      }
    ]
  end
end