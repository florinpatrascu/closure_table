defmodule CT.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string

      timestamps default: fragment("timezone('utc', now())")
    end

    create(unique_index(:authors, [:name]))
  end
end
