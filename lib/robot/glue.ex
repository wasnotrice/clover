defmodule Hugh.Robot.Glue do
  @doc """
  Get the robot's pid
  """
  @callback whereis_robot(pid) :: pid | nil

  @doc """
  Get the adapter's pid
  """
  @callback whereis_adapter(pid) :: pid | nil

  def module_and_pid(opts, key) when is_list(opts) and is_atom(key) do
    opts
    |> Keyword.fetch!(key)
    |> module_and_pid()
  end

  def module_and_pid(mod_or_mod_and_pid) do
    case mod_or_mod_and_pid do
      mod when is_atom(mod) -> {mod, nil}
      {mod, pid} -> {mod, pid}
    end
  end
end
