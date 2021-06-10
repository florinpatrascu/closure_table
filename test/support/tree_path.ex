defmodule CTE.TreePath do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "tree_paths" do
    belongs_to :parent_comment, CTE.Comment, foreign_key: :ancestor
    belongs_to :comment, CTE.Comment, foreign_key: :descendant
    field :path_length, :integer, default: 0
  end

  def changeset(path, params \\ %{}) do
    path
    |> cast(params, [:ancestor, :descendant, :path_length])
    |> validate_number(:ancestor, greater_than_or_equal_to: 0)
    |> validate_number(:descendant, greater_than_or_equal_to: 0)
  end
end
