defmodule CTTest do
  use CT.DataCase

  setup_all do
    Repo.delete_all(Author)
    Repo.delete_all(TreePath)

    authors = [
      # inserted_at: DateTime.utc_now()
      [name: "Olie"],
      [name: "Rolie"],
      [name: "Polie"]
    ]

    Repo.insert_all(Author, authors)

    :ok
  end

  describe "Forum" do
    test "Olie makes a comment" do
      assert %Author{name: "Olie"} = author = CT.get(Author, name: "Olie")

      assert {:ok,
              %{
                comment: %Comment{text: "Anybody here?"} = comment,
                tree: tree
              }} = CT.comment("Anybody here?", author)

      assert "Olie" == comment.author.name
      assert tree == [[comment.id, comment.id]]
    end
  end
end
