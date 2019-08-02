defmodule CT.Author do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "authors" do
    field :name, :string
    has_many :comments, CT.Comment, on_replace: :delete

    timestamps()
  end

  def changeset(author, params \\ %{}) do
    author
    |> cast(params, [:name, :inserted_at])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
