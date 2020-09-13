defmodule CTE.InMemory do
  @moduledoc """
  CT implementation using the memory adapter.

  The good ol' friends Rolie, Olie and Polie, debating the usefulness of this implementation :)
  You can watch them in action on: [youtube](https://www.youtube.com/watch?v=LTkmaE_QWMQ)

  After seeding the data, we'll have this graph:
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

  # %{comment_id => comment}
  @comments %{
    1 => %{id: 1, author: "Olie", comment: "Is Closure Table better than the Nested Sets?"},
    2 => %{id: 2, author: "Rolie", comment: "It depends. Do you need referential integrity?"},
    3 => %{id: 3, author: "Olie", comment: "Yeah."},
    7 => %{id: 7, author: "Rolie", comment: "Closure Table *has* referential integrity?"},
    4 => %{id: 4, author: "Polie", comment: "Querying the data it's easier."},
    5 => %{id: 5, author: "Olie", comment: "What about inserting nodes?"},
    6 => %{id: 6, author: "Rolie", comment: "Everything is easier, than with the Nested Sets."},
    8 => %{
      id: 8,
      author: "Olie",
      comment: "I'm sold! And I'll use its Elixir implementation! <3"
    },
    9 => %{id: 9, author: "Polie", comment: "w⦿‿⦿t!"},
    281 => %{author: "Polie", comment: "Rolie is right!", id: 281}
  }

  # [[ancestor, descendant], [..., ...], ...]
  @tree_paths []
  @insert_list [
    [1, 1],
    [1, 2],
    [2, 3],
    [3, 7],
    [1, 4],
    [4, 5],
    [4, 6],
    [6, 8],
    [6, 9]
  ]

  # -1
  # --2
  # ---3
  # ----7
  # --4
  # ---5
  # ---6
  # ----8
  # ----9

  use CTE,
    otp_app: :closure_table,
    adapter: CTE.Adapter.Memory,
    nodes: @comments,
    paths: @tree_paths

  def seed do
    @insert_list
    |> Enum.each(fn [ancestor, leaf] -> insert(leaf, ancestor) end)
  end
end
