try do
  Code.eval_file(".iex.exs", "~")
rescue
  Code.LoadError -> :rescued
end
