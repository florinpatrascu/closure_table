defmodule CT.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :text, :text, null: false
      add :author_id, references(:authors, type: :integer, on_delete: :delete_all), null: false

      timestamps default: fragment("timezone('utc', now())")
    end
  end
end
