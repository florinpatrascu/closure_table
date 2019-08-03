[![Hex.pm](https://img.shields.io/hexpm/dt/closure_table.svg?maxAge=2592000)](https://hex.pm/packages/closure_table)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/closure_table)

# Closure Table

> while an early preview, this library provides two adapters: an in-memory one, and one for using the  closure-table solution with Ecto; for your testing and development convenience.

The Closure Table solution is a simple and elegant way of storing hierarchies. It involves storing all paths through a tree, not just those with a direct parent-child relationship. You may want to chose this model, over the [Nested Sets model](https://en.wikipedia.org/wiki/Nested_set_model), should you need referential integrity and to assign nodes to multiple trees.

Throughout the various examples and tests, we will refer to the hierarchies depicted below, where we're modeling a hypothetical forum-like discussion between [Rolie, Olie and Polie](https://www.youtube.com/watch?v=LTkmaE_QWMQ), and their debate around the usefulness of this implementation :)

![Closure Table](assets/closure_table.png)

## Quick start

To start, you can simply use one `Adapter` from the ones provided, same way you'd use the Ecto's own Repo:

```elixir
defmodule CTM do
    use CTE,
      otp_app: :ct_empty,
      adapter: CTE.Adapter.Memory,
      nodes: %{
        1 => %{id: 1, author: "Olie", comment: "Is Closure Table better than the Nested Sets?"},
        2 => %{id: 2, author: "Rolie", comment: "It depends. Do you need referential integrity?"},
        3 => %{id: 3, author: "Polie", comment: "Yeah."}
      },
      paths: [[1, 1], [1, 2], [1, 3], [2, 2], [2, 3], [3, 3]]
  end
```

With the configuration above, the `:nodes` attribute is a map containing the comments our interlocutors made; these are "nodes", in CTE's parlance. When using the `CTE.Adapter.Ecto` implementation, the `:nodes` attribute will be a Schema (or a table name! In our initial implementation, the nodes definitions must have at least the `:id`, as one of their properties. This caveat will be lifted in a later implementation. The `:paths` attribute represents the parent-child relationship between the comments.

Add the `CTM` module to your main supervision tree:

```elixir
defmodule CTM.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: CTM.Supervisor]

    Supervisor.start_link([CTM], opts)
  end
end
```

And then using `iex -S mix`, for quickly experimenting with the CTE API, let's find the descendants of comment #1:

```elixir
iex» CTM.descendants(1)
{:ok, [3, 2]}
```

Please check the docs for more details and return from more updates!

Oh and there is a simple utility for helping you drawing your paths, using graphviz! From Rolie's comments, excerpt:

![](assets/dot.dot.dot.png)

Maybe useful?! If yes, then we'll let you find this function by yourself ;)

hint: _check the tests <3_

## Installation

If [available in Hex](https://hex.pm/packages/closure_table), the package can be installed
by adding `closure_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:closure_table, "~> 0.1"}
  ]
end
```

## Contributing

- [Fork this project](https://github.com/florinpatrascu/closure_table/fork)
- Create your feature branch (git checkout -b my-new-feature)
- Test (`mix test`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

## License

```txt
Copyright 2019 Florin T.PATRASCU

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
