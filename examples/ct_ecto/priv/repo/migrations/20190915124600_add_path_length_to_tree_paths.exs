defmodule CT.Repo.Migrations.AddPathLengthToTreePaths do
  use Ecto.Migration

  def change do
    alter table(:tree_paths) do
      add :path_length, :integer, null: false, default: 0
    end
  end
end
