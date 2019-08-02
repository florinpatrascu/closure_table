defmodule CT.MyCTE do
  @moduledoc """
  Comments hierarchy
  """
  use CTE,
    otp_app: :ct,
    adapter: CTE.Adapter.Ecto,
    repo: CT.Repo,
    nodes: CT.Comment,
    paths: CT.TreePath
end
