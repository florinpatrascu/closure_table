defmodule CTMTest do
  use ExUnit.Case
  doctest CTM

  test "greets the world" do
    assert CTM.hello() == :world
  end
end
