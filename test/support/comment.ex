defmodule CTE.Comment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "comments" do
    field :text, :string
    belongs_to :author, CTE.Author

    timestamps()
  end

  def changeset(params \\ %{}, %CTE.Author{} = author) do
    %CTE.Comment{}
    |> cast(params, [:text])
    |> validate_required(:text)
    |> validate_length(:text, min: 5)
    |> put_assoc(:author, author)
    |> foreign_key_constraint(:author_id, message: "unknown author")
  end
end
