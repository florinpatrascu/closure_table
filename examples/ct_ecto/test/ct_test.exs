defmodule CTTest do
  use CT.DataCase, async: false

  describe "Forum" do
    setup do
      authors = [
        # inserted_at: DateTime.utc_now()
        [name: "Olie"],
        [name: "Rolie"],
        [name: "Polie"]
      ]

      Repo.insert_all(Author, authors)
      :ok
    end

    test "Olie makes a comment" do
      assert %Author{name: "Olie"} = olie = CT.get(Author, name: "Olie")

      assert {:ok,
              %{
                comment: %Comment{text: "Anybody here?"} = o_comment,
                path: path
              }} = CT.comment("Anybody here?", olie)

      # assert "Olie" == o_comment.author.name
      # assert path == [[o_comment.id, o_comment.id]]

      # rolie = CT.get(Author, name: "Rolie")

      # assert {:ok,
      #         %{
      #           comment: %Comment{text: "I'm here"} = r_comment,
      #           path: path
      #         }} = CT.comment("I'm here", rolie)

      # assert "Rolie" == r_comment.author.name
      # assert path == [[r_comment.id, r_comment.id]]

      # polie = CT.get(Author, name: "Polie")

      # assert {:ok,
      #         %{
      #           comment: %Comment{text: "I'm here, as well!"} = p_comment,
      #           path: path
      #         }} = CT.comment("I'm here, as well!", polie)

      # assert "Polie" == p_comment.author.name
      # assert path == [[p_comment.id, p_comment.id]]

      # comment =
      #   o_comment
      #   |> CT.reply(r_comment)
      #   |> CT.reply(p_comment)

      # CT.MyCTE.descendants(comment.id, itself: true, node: true)
      # |> IO.inspect(label: "descendants")

      # CT.tree(o_comment)
      # |> IO.inspect(label: "")

      # CT.find_replies(o_comment)
      # |> IO.inspect(label: "")
    end
  end
end
