defmodule CT.Repo.Migrations.CreateTreePaths do
  use Ecto.Migration

  def change do
    create table(:tree_paths, primary_key: false) do
      add :ancestor, :bigint, null: false
      add :descendant, :bigint, null: false
    end

    create(index(:tree_paths, [:ancestor, :descendant]))
  end
end
