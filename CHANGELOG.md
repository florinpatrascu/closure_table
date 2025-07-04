# CHANGELOG

## 2.0.6

- The dependencies are now adjusted to allow for a broader range of compatible versions, enhancing flexibility and stability.

## 2.0.5

**Highlights**

- Updated code to support custom primary keys in CTE. You are no longer required to name your primary keys `id`. Although `id` remains the default, you now have the option to use your own keys and data types. Example:

  ```elixir
  use CTE,
    repo: Repo,
    nodes: Tag,
    paths: TagTreePath,
    options: %{
      node: %{primary_key: :name, type: :string},
      paths: %{
        ancestor: [type: :string],
        descendant: [type: :string]
      }
    }
  ```

**Improvements**

- Added support for nodes with custom primary keys
- Updated formatter configuration
- Modified Ecto queries to use dynamic fields instead of hardcoded 'id'
- Introduced new test cases for products and tags with custom IDs
- Adjusted existing tests to accommodate changes
- Updated migration files to include new tables and extensions

**Fixes**

- Finally crushed a sneaky bug that had been hiding out for way too long. The `depth` was stealthily hanging out in the descendants list and, on occasion, masquerading as one of the descendants if its value matched one of the nodes ids.

## 2.0.0

This version is introducing major breaking changes. We drop the concept of a CT Adapter and focus on using Ecto, for the core functions. The (in)memory adapter is gone.

Also important: we're going "process-less", simple, streamlined, efficient and maybe a tad fast(er)

This is very much a work in progress, with a list of immediate todos as follow:

- code cleanup and update the documentation
- allow the user to define her own:
  - primary key; name and maybe type
  - foreign key; name and maybe type - optional
  - callbacks (l8r)
- telemetry and better logging
- mix tasks for generating CT migrations
- support for "plugins" ..

## 1.1.5

- dependencies update

## 1.1.4

- code cleanup

## 1.1.3

- improved CT tree structure map representation. The node's children are a list now, to preserve their original order - suitable for rendering the tree in UI, etc.

## 1.1.2

- convert a CT tree structure to a nested map representation of the tree. This can be used for exporting this data as json, and so on. Thanks @greg-rychlewski

## 1.1.1

- requiring elixir 1.11 or newer
- CTE.Supervisor code cleanup, accepting a name parameter now
- fix the Memory Adapter example
- module documentation update; example was old and was missing the depth
- dependencies upgrade, for main and for the Ecto simple demo app

## 1.0.11

Minor changes:

- Dependencies updated to latest versions. New projects should no longer have dependency conflicts when installing closure_table
- Refactored Memory adapter's `delete` function (credo recommendation)
- Updated documentation to reflect that the options passed to the Ecto adapter's `move/3` are currently ignored
- Updated tests to remove some warnings

## 1.0.10

Major changes, and a couple of significant bug fixes.

- stable version! w⦿‿⦿t!
- deleting nodes using option: `limit: 1`, behave as expected now across adapters. To delete a leaf node set the limit option to: 1, and in this particular case all the nodes that reference the leaf will be assigned to the leaf's immediate ancestor. When using `limit: 0`, the leaf and all its descendants will be deleted!
- added tests for ASCII printing for both adapter; memory and Ecto
- the ancestors and the descendants are returned now using the proper order (based on their `:depth` value)
- improved tests for those cases where the outcome is complex or confusing
- updated dependencies

Warning: please use the move function with care! I believe it will require some refactoring and you'll get an eternal place in the CT's Hall of Fame if you'd like contributing to improving it!

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
