defmodule Hugh do
  @moduledoc """
  Documentation for Hugh.
  """

  use Application

  @registry Hugh.Registry

  def start(_type, _args) do
    Hugh.Supervisor.start_link(name: Hugh.App)
  end

  def start_supervised_robot(name, mod, adapter) do
    start_supervised_robot(name, mod, adapter, [])
  end

  def start_supervised_robot(name, mod, adapter, opts) when is_atom(adapter) do
    start_supervised_robot(name, mod, {adapter, []}, opts)
  end

  def start_supervised_robot(name, mod, {adapter, adapter_opts}, opts) do
    start_opts =
      opts
      |> Keyword.take([:timeout, :debug, :spawn_opt])
      |> Keyword.put(:name, via_tuple(name))

    adapter_opts = Keyword.put(adapter_opts, :robot_name, name)

    DynamicSupervisor.start_child(
      robot_supervisor(),
      mod.child_spec({adapter, adapter_opts}, start_opts)
    )
  end

  def stop_supervised_robot(robot) do
    case Registry.lookup(@registry, robot) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(robot_supervisor(), pid)
      [] -> :ok
    end
  end

  def start_robot(name, mod, adapter) do
    start_robot(name, mod, adapter, [])
  end

  def start_robot(name, mod, {adapter, adapter_opts}, opts) do
    start_opts =
      opts
      |> Keyword.take([:timeout, :debug, :spawn_opt])
      |> Keyword.put(:name, via_tuple(name))

    adapter_opts = Keyword.put(adapter_opts, :robot_name, :name)
    Hugh.Robot.start_link(mod, {adapter, adapter_opts}, start_opts)
  end

  def stop_robot(robot) do
    robot
    |> whereis_robot()
    |> Process.exit(:stop)
  end

  def whereis_robot(robot) do
    case Registry.lookup(@registry, robot) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def via_tuple(name), do: {:via, Registry, {@registry, name}}

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
