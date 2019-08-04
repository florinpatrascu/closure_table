defmodule CT do
  @moduledoc false

  alias CT.{MyCTE, Repo, Author, Comment}

  def get(schema, query) do
    Repo.get_by(schema, query)
  end

  @spec comment(String.t(), Author.t()) :: {:ok, list} | {:error, any}
  def comment(text, %Author{} = author) do
    cs = Comment.changeset(%{text: text}, author)

    with {:ok, comment} <- Repo.insert(cs),
         {:ok, path} <- MyCTE.insert(comment.id, comment.id) do
      {:ok, %{comment: comment, path: path}}
    else
      e -> {:error, e}
    end

    # Ecto.Multi.new()
    # |> Multi.insert(:comment, cs)
    # |> Multi.run(:path, &insert_node/2)
    # |> Repo.transaction()
  end

  @spec reply(Comment.t(), Comment.t()) :: {:ok, Comment.t()} | {:error, any()}
  def reply(parent_comment, child_comment) do
    with {:ok, _} <- MyCTE.insert(child_comment.id, parent_comment.id) do
      parent_comment
    else
      e -> {:error, e}
    end
  end

  @spec find_replies(Comment.t()) :: list
  def find_replies(comment) do
    MyCTE.descendants(comment.id, itself: false)
  end

  def tree(comment), do: MyCTE.tree(comment.id)

  # defp insert_node(_repo, %{comment: comment}) do
  #   MyCTE.insert(comment.id, comment.id)
  #   {:ok, [[comment.id, comment.id]]}
  # end
end
