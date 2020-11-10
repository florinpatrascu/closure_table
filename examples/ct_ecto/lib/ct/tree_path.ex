defmodule CT.TreePath do
  use Ecto.Schema
  import Ecto.Changeset
  alias CT.Comment

  @primary_key false

  schema "tree_paths" do
    belongs_to :parent_comment, Comment, foreign_key: :ancestor
    belongs_to :comment, Comment, foreign_key: :descendant
    field :path_length, :integer
  end

  def changeset(path, params \\ %{}) do
    path
    |> cast(params, [:ancestor, :descendant, :path_length])
    |> validate_number(:ancestor, greater_than_or_equal_to: 0)
    |> validate_number(:descendant, greater_than_or_equal_to: 0)
  end
end
