defmodule Hugh do
  @moduledoc """
  Documentation for Hugh.
  """

  use Application

  def start(_type, _args) do
    Hugh.Supervisor.start_link(name: Hugh.App)
  end

  def start_supervised_robot(mod, adapter) do
    start_supervised_robot(mod, adapter, [])
  end

  def start_supervised_robot(mod, adapter, opts) when is_atom(adapter) do
    start_supervised_robot(mod, {adapter, []}, opts)
  end

  def start_supervised_robot(mod, {adapter, adapter_opts}, opts) do
    start_opts = Keyword.take(opts, [:name, :timeout, :debug, :spawn_opt])
    adapter_opts = Keyword.put(adapter_opts, :robot_name, Keyword.get(start_opts, :name))

    DynamicSupervisor.start_child(
      robot_supervisor(),
      mod.child_spec({adapter, adapter_opts}, start_opts)
    )
  end

  def stop_supervised_robot(robot) do
    DynamicSupervisor.terminate_child(robot_supervisor(), robot)
  end

  def robot_supervisor, do: Hugh.Robots

  def format_error({:not_exported, {mod, function}}) do
    "#{mod} does not export function #{function}"
  end

  def format_error({:badarg, {mod, function, arg}}) do
    "bad argument for #{mod}.#{function}: #{arg}"
  end

  def format_error(reason) do
    reason
  end
end
