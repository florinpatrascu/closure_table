defmodule CTMTest do
  use ExUnit.Case

  describe "Closure Table, in Memory" do
    test "example descendants" do
      assert {:ok, [2, 3]} = CTM.descendants(1)
    end
  end
end
