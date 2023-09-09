# Closure Table

[![Hex.pm](https://img.shields.io/hexpm/dt/closure_table.svg?maxAge=2592000)](https://hex.pm/packages/closure_table)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/closure_table)

The Closure Table solution is a simple and elegant way of storing hierarchies. It involves storing all paths through a tree, not just those with a direct parent-child relationship. You may want to chose this model, over the [Nested Sets model](https://en.wikipedia.org/wiki/Nested_set_model), should you need referential integrity and to assign nodes to multiple trees.

Throughout the various examples and tests, we will refer to the hierarchies depicted below, where we're modeling a hypothetical forum-like discussion between [Rolie, Olie and Polie](https://www.youtube.com/watch?v=LTkmaE_QWMQ), and their debate around the usefulness of this implementation :)

![Closure Table](assets/closure_table.png)

## Quick start

### TODO

````

And then using `iex -S mix`, for quickly experimenting with the CTE API, let's find the descendants of comment #1:

```elixir
iex» CTM.descendants(1)
{:ok, [3, 2]}
iex> {:ok, tree} = CTT.tree(1)
...
iex> CTE.Utils.print_tree(tree, 1)
...
iex» CTE.Utils.print_tree(tree,1, callback: &({&2[&1].author <> ":", &2[&1].comment}))

Is Closure Table better than the Nested Sets?
└── It depends. Do you need referential integrity?
   └── Yeah.

````

Please check the docs for more details and return from more updates!

Oh and there is a simple utility for helping you drawing your paths, using graphviz! From Rolie's comments, excerpt:

![dot](assets/dot.dot.dot.png)

Maybe useful?! If yes, then we'll let you find this function by yourself ;)

hint: _check the tests <3_

## Installation

If [available in Hex](https://hex.pm/packages/closure_table), the package can be installed
by adding `closure_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:closure_table, "~> 2.0"}
  ]
end
```

## Contributing

- [Fork this project](https://github.com/florinpatrascu/closure_table/fork)
- Create your feature branch (git checkout -b my-new-feature)
- Setup database and test (`mix test`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

## License

```txt
Copyright 2023 Florin T.PATRASCU & the Contributors

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
