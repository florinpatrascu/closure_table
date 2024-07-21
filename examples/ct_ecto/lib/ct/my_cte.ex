defmodule CT.MyCTE do
  @moduledoc """
  Comments hierarchy
  """
  use CTE,
    repo: CT.Repo,
    nodes: CT.Comment,
    paths: CT.TreePath
end
