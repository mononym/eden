defmodule Eden.PlayerToken do
  use Eden.Web, :model

  schema "player_tokens" do
    field :player_id, :integer
    field :type, :string
    field :token, :string
    field :expiry, :string

    timestamps
  end

  @required_fields ~w(player_id type token expiry)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end