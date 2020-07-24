alias CT.Repo
alias CT.MyCTE

Repo.delete_all(CT.Comment)
Repo.delete_all(CT.Author)
Repo.delete_all(CT.TreePath)

"""
INSERT INTO "public"."authors" ("id", "name", "inserted_at", "updated_at") VALUES ('1', 'Olie', '2019-07-21 00:47:46', '2019-07-21 00:47:46');
INSERT INTO "public"."authors" ("id", "name", "inserted_at", "updated_at") VALUES ('2', 'Rolie', '2019-07-21 00:47:46', '2019-07-21 00:47:46');
INSERT INTO "public"."authors" ("id", "name", "inserted_at", "updated_at") VALUES ('3', 'Polie', '2019-07-21 00:47:46', '2019-07-21 00:47:46');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('1', 'Is Closure Table better than the Nested Sets?', '1', '2019-07-21 01:04:25', '2019-07-21 01:04:25');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('2', 'It depends. Do you need referential integrity?', '2', '2019-07-21 01:05:25', '2019-07-21 01:05:25');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('3', 'Yeah', '1', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('7', 'Closure Table *has* referential integrity?', '2', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('4', 'Querying the data it’s easier.', '3', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('5', 'What about inserting nodes?', '1', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('6', 'Everything is easier, than with the Nested Sets.', '2', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('8', 'I’m sold! And I’ll use its Elixir implementation! <3', '1', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('9', 'w⦿‿⦿t!', '3', '2019-07-21 01:10:35', '2019-07-21 01:10:35');
INSERT INTO "public"."comments" ("id", "text", "author_id", "inserted_at", "updated_at") VALUES ('281', 'Rolie is right!', '3', '2019-07-21 01:10:35', '2019-07-21 01:10:35');

"""
|> String.split("\n")
|> Enum.each(&Repo.query/1)

[
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
|> Enum.each(fn [ancestor, leaf] -> MyCTE.insert(leaf, ancestor) end)
