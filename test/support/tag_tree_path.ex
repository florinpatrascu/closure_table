defmodule CTE.TagTreePath do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias CTE.Tag

  @primary_key false
  @foreign_key_type :string

  schema "tag_tree_paths" do
    belongs_to :parent_tag, Tag, references: :name, foreign_key: :ancestor
    belongs_to :tag, Tag, references: :name, foreign_key: :descendant

    field :depth, :integer, default: 0
  end

  def changeset(path, params \\ %{}) do
    path
    |> cast(params, [:ancestor, :descendant, :depth])
    |> validate_number(:ancestor, greater_than_or_equal_to: 0)
    |> validate_number(:descendant, greater_than_or_equal_to: 0)
  end
end
