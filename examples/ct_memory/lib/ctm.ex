defmodule CTM do
  use CTE,
    otp_app: :ct_empty,
    adapter: CTE.Adapter.Memory,
    nodes: %{
      1 => %{id: 1, author: "Olie", comment: "Is Closure Table better than the Nested Sets?"},
      2 => %{id: 2, author: "Rolie", comment: "It depends. Do you need referential integrity?"},
      3 => %{id: 3, author: "Polie", comment: "Yeah."}
    },
    paths: [[1, 1, 0], [1, 2, 1], [1, 3, 2], [2, 2, 0], [2, 3, 1], [3, 3, 0]]
end
