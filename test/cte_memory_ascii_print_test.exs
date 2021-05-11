defmodule CTE.Memory.AsciiPrint.Test do
  use ExUnit.Case, async: true

  alias CTE.InMemory, as: CTM
  import ExUnit.CaptureIO

  describe "ASCII Printing" do
    setup do
      start_supervised(CTM)
      CTM.seed()

      :ok
    end

    test "valid CT in-memory adaptor" do
      assert %CTE{adapter: CTE.Adapter.Memory, nodes: _nodes, paths: _paths} = CTM.config()
    end

    test "print ascii tree " do
      print_io = fn ->
        {:ok, tree} = CTM.tree(1)
        CTE.Utils.print_tree(tree, 1, callback: &{&1, "(#{&1}) #{&2[&1].comment}"})
      end

      assert capture_io(print_io) =~ """
             (1) Is Closure Table better than the Nested Sets?
             ├── (2) It depends. Do you need referential integrity?
             │  └── (3) Yeah.
             │     └── (7) Closure Table *has* referential integrity?
             └── (4) Querying the data it's easier.
                ├── (5) What about inserting nodes?
                └── (6) Everything is easier, than with the Nested Sets.
                   ├── (8) I'm sold! And I'll use its Elixir implementation! <3
                   └── (9) w⦿‿⦿t!
             """

      print_io = fn ->
        # limit: 1
        assert :ok == CTM.delete(3)
        {:ok, tree} = CTM.tree(1)
        CTE.Utils.print_tree(tree, 1, callback: &{&1, "(#{&1}) #{&2[&1].comment}"})
      end

      assert capture_io(print_io) =~ """
             (1) Is Closure Table better than the Nested Sets?
             ├── (2) It depends. Do you need referential integrity?
             │  └── (7) Closure Table *has* referential integrity?
             └── (4) Querying the data it's easier.
                ├── (5) What about inserting nodes?
                └── (6) Everything is easier, than with the Nested Sets.
                   ├── (8) I'm sold! And I'll use its Elixir implementation! <3
                   └── (9) w⦿‿⦿t!
             """
    end
  end
end
