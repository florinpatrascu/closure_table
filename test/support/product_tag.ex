defmodule CTE.ProductTag do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :string

  schema "products_tags" do
    belongs_to :product, CTE.Product,
      foreign_key: :product_name,
      references: :name,
      primary_key: true

    belongs_to :tag, CTE.Tag,
      foreign_key: :tag_name,
      references: :name,
      primary_key: true
  end

  @doc false
  def changeset(product_tag, attrs) do
    product_tag
    |> cast(attrs, [:product_name, :tag_name])
    |> validate_required([:product_name, :tag_name])
    |> unique_constraint([:product_name, :tag_name])
    |> foreign_key_constraint(:product_name)
    |> foreign_key_constraint(:tag_name)
  end
end
