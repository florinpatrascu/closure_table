defmodule CTE.Tag do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]
  @primary_key false

  schema "tags" do
    field :name, :string, primary_key: true

    many_to_many :products, CTE.Product,
      join_through: CTE.ProductTag,
      join_keys: [name: :name, tag: :tag]

    timestamps()
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
