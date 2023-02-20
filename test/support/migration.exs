defmodule CTE.Migration do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string

      timestamps default: fragment("timezone('utc', now())")
    end

    create(unique_index(:authors, [:name]))

    create table(:comments) do
      add :text, :text, null: false
      add :author_id, references(:authors, type: :integer, on_delete: :delete_all), null: false

      timestamps default: fragment("timezone('utc', now())")
    end

    create table(:tree_paths, primary_key: false) do
      add :ancestor, :bigint, null: false
      add :descendant, :bigint, null: false
    end

    create(index(:tree_paths, [:ancestor, :descendant]))

    alter table(:tree_paths) do
      add :depth, :integer, null: false, default: 0
    end
  end
end
