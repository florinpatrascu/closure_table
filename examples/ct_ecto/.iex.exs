try do
  Code.eval_file(".iex.exs", "~")
rescue
  Code.LoadError -> :rescued
end

alias CT.{MyCTE, Repo, Author, Comment, TreePath}
alias Ecto.Multi
