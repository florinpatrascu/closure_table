# CT Ecto

Demonstrating the Closure Table (CT) adapter for Ecto ~> 3.4

## Quick start

This demo will create everything you need to start experimenting with the Ecto adapter for CT, including seeding the database with a simple graph. Initialize the project with these simple commands:

```elixir
$ mix do deps.get, compile
$ mix ecto.setup
```

And jump into the IEx shell, with: `iex -S mix`

```elixir
iex» MyCTE.tree(1, depth: 1)
{:ok,
 %{
   nodes: %{
     1 => %CT.Comment{
       __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
       author: #Ecto.Association.NotLoaded<association :author is not loaded>,
       author_id: 1,
       id: 1,
       inserted_at: ~U[2019-07-21 01:04:25Z],
       text: "Is Closure Table better than the Nested Sets?",
       updated_at: ~U[2019-07-21 01:04:25Z]
     },
     2 => %CT.Comment{
       __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
       author: #Ecto.Association.NotLoaded<association :author is not loaded>,
       author_id: 2,
       id: 2,
       inserted_at: ~U[2019-07-21 01:05:25Z],
       text: "It depends. Do you need referential integrity?",
       updated_at: ~U[2019-07-21 01:05:25Z]
     },
     4 => %CT.Comment{
       __meta__: #Ecto.Schema.Metadata<:loaded, "comments">,
       author: #Ecto.Association.NotLoaded<association :author is not loaded>,
       author_id: 3,
       id: 4,
       inserted_at: ~U[2019-07-21 01:10:35Z],
       text: "Querying the data it’s easier.",
       updated_at: ~U[2019-07-21 01:10:35Z]
     }
   },
   paths: [[1, 1, 0], [1, 2, 1], [1, 4, 1], [2, 2, 0], [4, 4, 0]]
 }}

iex» authors = for author <- Repo.all(Author), into: %{}, do: {author.id, author.name}
iex» CTE.Utils.print_tree(tree,1, callback: &({&1, "#{authors[&2[&1].author_id]}: #{&2[&1].text}"}))

Olie: Is Closure Table better than the Nested Sets?
├── Rolie: It depends. Do you need referential integrity?
│  └── Olie: Yeah
│     └── Rolie: Closure Table *has* referential integrity?
└── Polie: Querying the data it’s easier.
   ├── Olie: What about inserting nodes?
   └── Rolie: Everything is easier, than with the Nested Sets.
      ├── Olie: I’m sold! And I’ll use its Elixir implementation! <3
      └── Polie: w⦿‿⦿t!
```
