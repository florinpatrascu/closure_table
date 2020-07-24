# CHANGELOG

## 1.0.0 (rc)

This is a new version introducing breaking changes. Please continue to use 0.2.1 for production, until we hit 1.2 unless you know what you're doing =)

- the CT Ecto demo setup is much friendlier now, and it is also seeding the new database with demo data
- the labels support functions now
- the paths returned will always have the depth, as the 3rd element (breaking chance)
- support for pretty printing trees. Example:

```elixir
  {:ok, tree} = CTT.tree(1)
  CTE.Utils.print_tree(tree,1, callback: &({&2[&1].author <> ":", &2[&1].comment}))

  Olie: Is Closure Table better than the Nested Sets?
  └── Rolie: It depends. Do you need referential integrity?
   └── Olie: Yeah.
```

## 0.2.1

- support for immediate parent or child query #1; introducing the requirements for an extra field, in the tree_paths support table: `depth`

## 0.1.6

- better tests covering the Ecto Adapter example

## 0.1.4

- mix config fix.

## 0.1.3

- fixing the examples using the CTE Adapter for Ecto - WIP

## 0.1.1

- minor text adjustments
- removing redundant content

## 0.1.0

initial version
