defmodule CT do
  @moduledoc false

  alias CT.{MyCTE, Repo, Author, Comment, TreePath}
  alias Ecto.Multi

  def get(schema, query) do
    Repo.get_by(schema, query)
  end

  @spec comment(String.t(), Author.t()) :: {:ok}
  def comment(comment, %Author{} = author) do
    comment = Comment.changeset(%{text: comment}, author)

    Multi.new()
    |> Multi.insert(:comment, comment)
    |> Multi.run(:tree, &insert_node/2)
    |> Repo.transaction()
  end

  defp insert_node(_repo, %{comment: comment} = changes) do
    CH.insert(comment.id, comment.id)
    {:ok, [[comment.id, comment.id]]}
  end
end
