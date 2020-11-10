# CHANGELOG

## 1.0.10

Major changes, and a couple of significant bug fixes.

- stable version! w⦿‿⦿t!
- deleting nodes using option: `limit: 1`, behave as expected now across adapters. To delete a leaf node set the limit option to: 1, and in this particular case all the nodes that reference the leaf will be assigned to the leaf's immediate ancestor. When using `limit: 0`, the leaf and all its descendants will be deleted!
- added tests for ASCII printing for both adapter; memory and Ecto
- the ancestors and the descendants are returned now using the proper order (based on their `:path_length` value)
- improved tests for those cases where the outcome is complex or confusing
- updated dependencies

Warning: please use the move function with care! I believe it will require some refactoring and you'll get an eternal place in the CT's Hall of Fame if you'd like contributing to improving it!

## 1.0.0 (rc)

This is a new version introducing breaking changes. Please continue to use 0.2.1 for production, until we hit 1.2 unless you know what you're doing =)

- the CT Ecto demo setup is much friendlier now, and it is also seeding the new database with demo data
- the labels support functions now
- the paths returned will always have the path_length, as the 3rd element (breaking chance)
- support for pretty printing trees. Example:

```elixir
  {:ok, tree} = CTT.tree(1)
  CTE.Utils.print_tree(tree,1, callback: &({&2[&1].author <> ":", &2[&1].comment}))

  Olie: Is Closure Table better than the Nested Sets?
  └── Rolie: It depends. Do you need referential integrity?
   └── Olie: Yeah.
```

## 0.2.1

- support for immediate parent or child query #1; introducing the requirements for an extra field, in the tree_paths support table: `path_length`

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
