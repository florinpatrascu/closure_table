defmodule CTE.Migration do
  use Ecto.Migration

  @timestamps fragment("timezone('utc', now())")

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext")

    create table(:authors) do
      add :name, :string

      timestamps default: @timestamps
    end

    create(unique_index(:authors, [:name]))

    create table(:comments) do
      add :text, :text, null: false
      add :author_id, references(:authors, type: :integer, on_delete: :delete_all), null: false

      timestamps default: @timestamps
    end

    create table(:tree_paths, primary_key: false) do
      add :ancestor, :bigint, null: false
      add :descendant, :bigint, null: false
      add :depth, :integer, null: false, default: 0
    end

    create index(:tree_paths, [:ancestor, :descendant])

    # new support for testing nodes with custom IDs
    # ---------------------------------------------
    #
    create table(:products, primary_key: false) do
      add :name, :citext, null: false, primary_key: true
      add :description, :text, comment: "A generic description, but can be null/empty"

      timestamps default: @timestamps
    end

    create table(:tags, primary_key: false) do
      add :name, :citext, null: false, primary_key: true

      timestamps default: @timestamps
    end

    create table(:products_tags, primary_key: false) do
      add :product_name,
          references(:products, column: :name, on_delete: :delete_all, type: :citext),
          null: false

      add :tag_name,
          references(:tags, column: :name, on_delete: :delete_all, type: :citext),
          null: false
    end

    create unique_index(:products_tags, [:product_name, :tag_name])

    create table(:tag_tree_paths, primary_key: false) do
      add :ancestor, :string, null: false
      add :descendant, :string, null: false
      add :depth, :integer, null: false, default: 0
    end

    create index(:tag_tree_paths, [:ancestor, :descendant])
  end
end
