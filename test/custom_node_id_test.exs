defmodule CTE.CustomNodeIdTest do
  use CTE.DataCase, async: true

  import ExUnit.CaptureIO

  defmodule Tags do
    @moduledoc """
    Tagging hierarchy
    """
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
  end

  setup_all [:seed]

  test "products have proper tags" do
    assert %Product{name: "Apple", tags: tags} =
             Product
             |> Repo.get_by(name: "apPle")
             |> Repo.preload(:tags)

    tags = sorted_tags(tags)
    assert ~w/food fruit/ == tags

    assert %Product{name: "Carrot", tags: tags} =
             Product
             |> Repo.get_by(name: "carROT")
             |> Repo.preload(:tags)

    tags = sorted_tags(tags)
    assert ~w/food vegetable/ == tags
  end

  describe "Tags" do
    test "get a (case) insensitive Apple" do
      assert %Tag{name: "apple"} = Repo.get(Tag, "ApPlE")
    end
  end

  describe "Descendants having different types of PKs" do
    test "Retrieve all descendants of the fruits, including itself" do
      assert {:ok, ~w/fruit apple orange berry tomato/} ==
               Tags.descendants("fruit", itself: true)
    end

    test "Retrieve top 3 descendants of the fruits, including itself" do
      assert {:ok, ~w/fruit apple orange/} == Tags.descendants("fruit", limit: 3, itself: true)
    end

    test "Retrieve top 3 descendants of the fruits, exluding itself" do
      assert {:ok, ~w/apple orange berry/} == Tags.descendants("fruit", limit: 3)
    end

    test "Retrieve descendants of the Meat, as %Tag{}" do
      assert {:ok, [%CTE.Tag{name: "meat"}, %CTE.Tag{name: "burger"}]} =
               Tags.descendants("meat", limit: 2, itself: true, nodes: true)
    end
  end

  describe "Ancestors having different types of PKs" do
    test "Retrieve ancestors of comment tomato, excluding itself" do
      assert {:ok, ~w/food fruit/} == Tags.ancestors("tomato", limit: 2)
    end

    test "Trace the lineage of Mr. Tomato, including itself" do
      assert {:ok, ~w/food fruit berry tomato/} == Tags.ancestors("tomato", itself: true)
    end

    test "Retrieve ancestors of the Burger, as %Tag{}" do
      assert {:ok, [%CTE.Tag{name: "food"}, %CTE.Tag{name: "meat"}]} =
               Tags.ancestors("burger", nodes: true)
    end
  end

  describe "hierarchical tags paths operations" do
    test "add a descendant of Food " do
      assert {:ok, [~w/food cheesecake/, ~w/cheesecake cheesecake/]} ==
               Tags.insert("cheesecake", "food")

      assert {:ok, [%CTE.Tag{name: "food"}, %CTE.Tag{name: "cheesecake"}]} =
               Tags.ancestors("cheesecake", itself: true, nodes: true)
    end

    test "delete a leaf" do
      assert {:ok, ~w/burger/} == Tags.descendants("meat", limit: 1)
      assert {:ok, %{deleted: {3, _}, updated: {0, _}}} = Tags.delete("burger", limit: 1)

      refute {:ok, ~w/burger/} == Tags.descendants("meat", limit: 1)
      assert {:ok, []} == Tags.descendants("meat", limit: 1)
    end

    test "the food ... tree" do
      assert {:ok,
              %{
                nodes: %{
                  "apple" => %CTE.Tag{
                    name: "apple"
                  },
                  "berry" => %CTE.Tag{
                    name: "berry"
                  },
                  "fruit" => %CTE.Tag{
                    name: "fruit"
                  },
                  "orange" => %CTE.Tag{
                    name: "orange"
                  },
                  "tomato" => %CTE.Tag{
                    name: "tomato"
                  }
                },
                paths: [
                  ["fruit", "fruit", 0],
                  ["fruit", "apple", 1],
                  ["apple", "apple", 0],
                  ["fruit", "orange", 1],
                  ["orange", "orange", 0],
                  ["fruit", "berry", 1],
                  ["berry", "berry", 0],
                  ["fruit", "tomato", 2],
                  ["berry", "tomato", 1],
                  ["tomato", "tomato", 0]
                ]
              }} = Tags.tree("fruit")
    end

    test "print ascii tree using the Ecto Adapter" do
      print_io = fn ->
        {:ok, tree} = Tags.tree("food")
        CTE.Utils.print_tree(tree, "food", callback: &{&1, "#{&2[&1].name}"})
      end

      assert capture_io(print_io) =~ """
             food
             ├── vegetable
             ├── fruit
             │  ├── apple
             │  ├── orange
             │  └── berry
             │     └── tomato
             └── meat
                └── burger
             """
    end

    test "tree_to_map/3" do
      {:ok, fruity} = Tags.tree("fruit")
      tree_map = CTE.Utils.tree_to_map(fruity, "fruit", callback: &Map.take(&1, [:name]))

      assert tree_map == %{
               "id" => "fruit",
               "node" => %{name: "fruit"},
               "children" => [
                 %{"id" => "apple", "node" => %{name: "apple"}, "children" => []},
                 %{"id" => "orange", "node" => %{name: "orange"}, "children" => []},
                 %{
                   "id" => "berry",
                   "node" => %{name: "berry"},
                   "children" => [
                     %{"id" => "tomato", "node" => %{name: "tomato"}, "children" => []}
                   ]
                 }
               ]
             }
    end
  end

  # private stuff
  # -------------
  #
  defp seed(_ctx) do
    Repo.delete_all(Product)
    Repo.delete_all(Tag)
    Repo.delete_all(ProductTag)
    Repo.delete_all(TagTreePath)

    Repo.insert_all(
      Product,
      for name <- ~w/Apple Orange Plum Banana Carrot Lettuce Peach Strawberry/ do
        %{name: name}
      end
    )

    Repo.insert_all(
      Tag,
      for name <-
            ~w/food fruit vegetable meat burger things furniture table chair desk apple orange tomato berry cheesecake/ do
        %{name: name}
      end
    )

    apple = Repo.get_by(Product, name: "Apple")
    carrot = Repo.get_by(Product, name: "carrot")

    food_tag = Repo.get_by(Tag, name: "food")
    fruit_tag = Repo.get_by(Tag, name: "fruit")
    vegetable_tag = Repo.get_by(Tag, name: "vegetable")

    Repo.insert_all(ProductTag, [
      # fruits
      %{product_name: apple.name, tag_name: food_tag.name},
      %{product_name: apple.name, tag_name: fruit_tag.name},
      # veggies
      %{product_name: carrot.name, tag_name: food_tag.name},
      %{product_name: carrot.name, tag_name: vegetable_tag.name}
    ])

    [
      ~w/food food/,
      ~w/food vegetable/,
      ~w/food fruit/,
      ~w/food meat/,
      ~w/meat burger/,
      ~w/things things/,
      ~w/things furniture/,
      ~w/furniture table/,
      ~w/furniture chair/,
      ~w/fruit apple/,
      ~w/fruit orange/,
      ~w/furniture desk/,
      ~w/fruit berry/,
      ~w/berry tomato/
    ]
    |> Enum.each(fn [ancestor, leaf] -> Tags.insert(leaf, ancestor) end)

    if System.get_env("PRINT_TREE_4TEST") do
      IO.puts("")
      {:ok, tree} = Tags.tree("food")
      CTE.Utils.print_tree(tree, "food", callback: &{&1, "#{&2[&1].name}"})
    end

    :ok
  end

  defp sorted_tags(tags) do
    tags
    |> Enum.map(& &1.name)
    |> Enum.sort()
  end
end
