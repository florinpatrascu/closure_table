defmodule CTE.Memory.Test do
  use ExUnit.Case, async: true

  alias CTE.InMemory, as: CT

  @digraph "digraph \"6) Rolie\nEverything is easier, than with the Nested Sets.\" {\n  \"6) Rolie\nEverything is easier, than with the Nested Sets.\" -> \"8) Olie\nI'm sold! And I'll use its Elixir implementation! <3\"\n  \"8) Olie\nI'm sold! And I'll use its Elixir implementation! <3\" -> \"8) Olie\nI'm sold! And I'll use its Elixir implementation! <3\"\n  \"6) Rolie\nEverything is easier, than with the Nested Sets.\" -> \"9) Polie\nw⦿‿⦿t!\"\n  \"9) Polie\nw⦿‿⦿t!\" -> \"9) Polie\nw⦿‿⦿t!\"\n}\n"

  defmodule CTEmpty do
    use CTE,
      otp_app: :ct_empty,
      adapter: CTE.Adapter.Memory,
      nodes: [],
      paths: []
  end

  describe "Config" do
    setup do
      start_supervised(CT)
      CT.seed()
    end

    test "info" do
      assert %CTE{adapter: CTE.Adapter.Memory, nodes: [], paths: []} == CTEmpty.config()
      assert %CTE{adapter: CTE.Adapter.Memory, nodes: nodes, paths: paths} = CT.config()
    end
  end

  describe "Descendants" do
    setup do
      start_supervised(CT)
      start_supervised(CTEmpty)

      CT.seed()
      :ok
    end

    test "Retrieve descendants of comment #2, including itself" do
      assert {:ok, [1, 2]} == CT.descendants(1, limit: 2, itself: true)
    end

    test "Retrieve descendants of comment #1, excluding itself" do
      assert {:ok, [2, 3]} == CT.descendants(1, limit: 2)
      assert {:ok, [2, 3, 7, 4, 5, 6, 8, 9]} == CT.descendants(1)
    end

    test "Retrieve all descendants of comment #2, including itself" do
      assert {:ok, [2, 3, 7]} = CT.descendants(2, itself: true)
    end

    test "Retrieve descendants of comment #2, with limit" do
      assert {:ok, [3, 7]} == CT.descendants(2, limit: 3)
    end

    test "Retrieve descendants of comment #2, as comments" do
      assert {:ok,
              [
                %{
                  id: 2,
                  comment: "It depends. Do you need referential integrity?",
                  author: "Rolie"
                }
              ]} ==
               CT.descendants(1, limit: 1, nodes: true)
    end

    test "Retrieve descendants of comment #1, excluding itself, with depth" do
      assert {:ok, [2, 3, 7, 4, 5, 6, 8, 9]} == CT.descendants(1)
      assert {:ok, [2, 4]} == CT.descendants(1, depth: 1)
      assert {:ok, [2, 3, 4, 5, 6]} == CT.descendants(1, depth: 2)
      assert {:ok, [2, 3, 7, 4, 5, 6, 8, 9]} == CT.descendants(1, depth: 5)
      assert {:ok, []} == CT.descendants(1, depth: -5)
    end
  end

  describe "Ancestors" do
    setup do
      start_supervised(CT)
      start_supervised(CTEmpty)

      CT.seed()
      :ok
    end

    test "Retrieve ancestors of comment #6, excluding itself" do
      assert {:ok, [1, 4]} == CT.ancestors(6, limit: 2)
    end

    test "Retrieve ancestors of comment #6, including itself" do
      assert {:ok, [1, 4, 6]} == CT.ancestors(6, itself: true)
    end

    test "Retrieve ancestors of comment #6, as comments" do
      assert {:ok,
              [
                %{
                  author: "Olie",
                  comment: "Is Closure Table better than the Nested Sets?",
                  id: 1
                },
                %{author: "Polie", comment: "Querying the data it's easier.", id: 4}
              ]} == CT.ancestors(6, nodes: true)
    end

    test "Retrieve ancestors of comment #6 as comments, with limit" do
      assert {:ok,
              [%{author: "Olie", comment: "Is Closure Table better than the Nested Sets?", id: 1}]} ==
               CT.ancestors(6, limit: 1, nodes: true)
    end

    test "Retrieve ancestors of comment #6, including itself, with depth" do
      assert {:ok, [1, 4, 6]} == CT.ancestors(6, itself: true)
      assert {:ok, [4, 6]} == CT.ancestors(6, itself: true, depth: 1)
      assert {:ok, [1, 4, 6]} == CT.ancestors(6, itself: true, depth: 2)
      assert {:ok, [1, 4, 6]} == CT.ancestors(6, itself: true, depth: 3)
      assert {:ok, [6]} == CT.ancestors(6, itself: true, depth: -3)
    end
  end

  describe "Tree paths operations" do
    setup do
      start_supervised(CT)

      CT.seed()
      :ok
    end

    test "insert descendant of comment #7" do
      assert {:ok,
              [
                [1, 281, 4],
                [2, 281, 3],
                [3, 281, 2],
                [7, 281, 1],
                [281, 281, 0]
              ]} == CT.insert(281, 7)

      assert {:ok, [%{author: "Polie", comment: "Rolie is right!", id: 281}]} ==
               CT.descendants(7, limit: 1, nodes: true)
    end

    test "delete leaf; comment #9" do
      assert {:ok, [%{comment: "w⦿‿⦿t!"}]} =
               CT.descendants(9, limit: 1, itself: true, nodes: true)

      assert :ok == CT.delete(9, limit: 1)

      assert {:ok, []} == CT.descendants(9, limit: 1, itself: true, nodes: true)
      assert {:ok, []} == CT.descendants(9, limit: 1)
    end

    test "delete subtree; comment #6 and its descendants" do
      assert {:ok, [6, 8, 9]} == CT.descendants(6, itself: true)
      assert :ok == CT.delete(6)
      assert {:ok, []} == CT.descendants(6, itself: true)
    end

    test "delete subtree w/o any leafs; comment #5 and its descendants" do
      assert {:ok, [5]} == CT.descendants(5, itself: true)
      assert :ok == CT.delete(5)
      assert {:ok, []} == CT.descendants(5, itself: true)
    end

    test "delete whole tree, from its root; comment #1" do
      assert {:ok, [1, 2, 3, 7, 4, 5, 6, 8, 9]} == CT.descendants(1, itself: true)
      assert :ok == CT.delete(1)
      assert {:ok, []} == CT.descendants(1, itself: true)
    end

    test "move subtree; comment #6, to a child of comment #3" do
      assert {:ok, [1, 2]} == CT.ancestors(3)
      assert {:ok, [7]} == CT.descendants(3)

      assert {:ok, [1, 4]} == CT.ancestors(6)
      assert {:ok, [8, 9]} == CT.descendants(6)

      assert :ok = CT.move(6, 3)

      assert {:ok, [1, 2, 3]} == CT.ancestors(6)
      assert {:ok, [1, 2, 3, 6]} == CT.ancestors(8)
      assert {:ok, [1, 2, 3, 6]} == CT.ancestors(9)

      assert {:ok, [3]} == CT.ancestors(6, depth: 1)
      assert {:ok, [6]} == CT.ancestors(8, depth: 1)
      assert {:ok, [6]} == CT.ancestors(9, depth: 1)

      assert {:ok, [7, 6, 8, 9]} == CT.descendants(3)
    end

    test "return the descendants tree of comment #4" do
      assert {:ok,
              %{
                nodes: %{
                  6 => %{
                    author: "Rolie",
                    comment: "Everything is easier, than with the Nested Sets.",
                    id: 6
                  },
                  8 => %{
                    author: "Olie",
                    comment: "I'm sold! And I'll use its Elixir implementation! <3",
                    id: 8
                  },
                  9 => %{author: "Polie", comment: "w⦿‿⦿t!", id: 9}
                },
                paths: [
                  [6, 6, 0],
                  [6, 8, 1],
                  [8, 8, 0],
                  [6, 9, 1],
                  [9, 9, 0]
                ]
              }} == CT.tree(6)
    end

    test "return the direct descendants tree of comment #1" do
      assert {:ok,
              %{
                nodes: %{
                  2 => %{
                    author: "Rolie",
                    comment: "It depends. Do you need referential integrity?",
                    id: 2
                  },
                  3 => %{
                    author: "Olie",
                    comment: "Yeah.",
                    id: 3
                  }
                },
                paths: [[2, 2, 0], [2, 3, 1], [3, 3, 0]]
              }} = CT.tree(2, depth: 1)
    end
  end

  describe "Tree utils" do
    setup do
      start_supervised(CT)
      CT.seed()
      :ok
    end

    test "print the tree below comment #4" do
      assert {:ok, tree} = CT.tree(6)

      assert %{
               nodes: %{
                 6 => %{
                   author: "Rolie",
                   comment: "Everything is easier, than with the Nested Sets.",
                   id: 6
                 },
                 8 => %{
                   author: "Olie",
                   comment: "I'm sold! And I'll use its Elixir implementation! <3",
                   id: 8
                 },
                 9 => %{author: "Polie", comment: "w⦿‿⦿t!", id: 9}
               },
               paths: [
                 [6, 6, 0],
                 [6, 8, 1],
                 [8, 8, 0],
                 [6, 9, 1],
                 [9, 9, 0]
               ]
             } == tree

      labels = [:id, ")", " ", :author, "\n", :comment]
      assert @digraph == CTE.Utils.print_dot(tree, labels: labels)

      # File.write!("polie.dot", @digraph)
      # dot -Tpng polie.dot -o polie.png
      # System.cmd("dot", ~w/-Tpng polie.dot -o polie.png/)
    end

    test "raw tree representation, for print" do
      assert {:ok, tree} = CT.tree(1)
      # CTE.Utils.print_tree(tree, 1, callback: &{&1, "#{&2[&1].author}: #{&2[&1].comment}"})

      assert [
               {0, "Olie: Is Closure Table better than the Nested Sets?"},
               {1, "Rolie: It depends. Do you need referential integrity?"},
               {2, "Olie: Yeah."},
               {3, "Rolie: Closure Table *has* referential integrity?"},
               {1, "Polie: Querying the data it's easier."},
               {2, "Olie: What about inserting nodes?"},
               {2, "Rolie: Everything is easier, than with the Nested Sets."},
               {3, "Olie: I'm sold! And I'll use its Elixir implementation! <3"},
               {3, "Polie: w⦿‿⦿t!"}
             ] =
               CTE.Utils.print_tree(tree, 1,
                 callback: &{&1, "#{&2[&1].author}: #{&2[&1].comment}"},
                 raw: true
               )

      assert {:ok, tree} = CT.tree(6)

      assert [
               {0, "Rolie: Everything is easier, than with the Nested Sets."},
               {1, "Olie: I'm sold! And I'll use its Elixir implementation! <3"},
               {1, "Polie: w⦿‿⦿t!"}
             ] =
               CTE.Utils.print_tree(tree, 6,
                 callback: &{&1, "#{&2[&1].author}: #{&2[&1].comment}"},
                 raw: true
               )
    end
  end
end
