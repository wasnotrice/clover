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
    start_opts = Keyword.take(opts, [:timeout, :debug, :spawn_opt])

    DynamicSupervisor.start_child(
      robot_supervisor(),
      Hugh.Robot.Supervisor.child_spec({name, mod, {adapter, adapter_opts}}, start_opts)
    )
  end

  @spec stop_supervised_robot(String.t()) :: :ok | {:error, :not_found}
  def stop_supervised_robot(robot) do
    case whereis_robot_supervisor(robot) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(robot_supervisor(), pid)
    end
  end

  @doc """
  Start a robot outside of the `Hugh` supervision tree.

  The robot's pid will still be registered   in the `Hugh` registry, but the processes will not be
  supervised by `Hugh`, and you can manage link the robot into your own supervision tree. Returns
  the `pid` of the robot's supervisor.

  To stop the robot, call `Supervisor.stop(pid)`.
  """
  def start_robot(name, mod, adapter) do
    start_robot(name, mod, adapter, [])
  end

  def start_robot(name, mod, {adapter, adapter_opts}, opts) do
    start_opts = Keyword.take(opts, [:timeout, :debug, :spawn_opt])
    Hugh.Robot.Supervisor.start_link({name, mod, {adapter, adapter_opts}}, start_opts)
  end

  def registry, do: @registry

  def whereis_robot(robot) do
    case Registry.lookup(@registry, robot) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def whereis_robot_adapter(robot) do
    case Registry.lookup(@registry, {robot, :adapter}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def whereis_robot_supervisor(robot) do
    case whereis_robot(robot) do
      nil ->
        nil

      pid ->
        robot_supervisor()
        |> DynamicSupervisor.which_children()
        |> find_supervisor_for_robot(pid)
    end
  end

  defp find_supervisor_for_robot(supervisors, robot_pid) do
    supervisors
    |> Enum.find(fn child ->
      child
      |> child_pid()
      |> Supervisor.which_children()
      |> Enum.find(fn child -> child_pid(child) == robot_pid end)
    end)
    |> case do
      nil -> nil
      child -> child_pid(child)
    end
  end

  defp child_pid({_, pid, _, _}), do: pid

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
