defmodule CTE.Product do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]
  @primary_key false

  schema "products" do
    field :name, :string

    has_many :product_tags, CTE.ProductTag, references: :name

    has_many :tags, through: [:product_tags, :tag]

    timestamps()
  end

  def changeset(product, params \\ %{}) do
    product
    |> cast(params, [:name])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
