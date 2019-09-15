defmodule CT.Repo.Migrations.AddDepthToTreePaths do
  use Ecto.Migration

  def change do
    alter table(:tree_paths) do
      add :depth, :integer, null: false, default: 0
    end
  end
end
