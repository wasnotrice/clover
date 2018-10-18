defmodule Clover do
  @moduledoc """
  The Clover application
  """

  use Application

  @registry Clover.Registry
  @robot_supervisor Clover.Robots

  @doc false
  def start(_type, _args) do
    Clover.Supervisor.start_link(@robot_supervisor, name: Clover.App)
  end

  def start_supervised_robot(name, robot, adapter, opts \\ [])

  def start_supervised_robot(name, robot, adapter, opts) when is_atom(robot) do
    start_supervised_robot(name, {robot, []}, adapter, opts)
  end

  def start_supervised_robot(name, {robot, robot_arg}, adapter, opts) when is_atom(adapter) do
    start_supervised_robot(name, {robot, robot_arg}, {adapter, []}, opts)
  end

  def start_supervised_robot(name, {robot, robot_arg}, {adapter, adapter_arg}, opts) do
    DynamicSupervisor.start_child(
      @robot_supervisor,
      Clover.Robot.Supervisor.child_spec({name, {robot, robot_arg}, {adapter, adapter_arg}}, opts)
    )
  end

  @spec stop_supervised_robot(String.t()) :: :ok | {:error, :not_found}
  def stop_supervised_robot(robot) do
    case whereis_robot_supervisor(robot) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(@robot_supervisor, pid)
    end
  end

  @doc """
  Start a robot outside of the `Clover` supervision tree.

  The robot's pid will still be registered   in the `Clover` registry, but the processes will not be
  supervised by `Clover`, and you can manage link the robot into your own supervision tree. Returns
  the `pid` of the robot's supervisor.

  To stop the robot, call `Supervisor.stop(pid)`.
  """
  def start_robot(name, robot, adapter, opts \\ [])

  def start_robot(name, robot, adapter, opts) when is_atom(robot) do
    start_robot(name, {robot, []}, adapter, opts)
  end

  def start_robot(name, {robot, robot_arg}, adapter, opts) when is_atom(adapter) do
    start_robot(name, {robot, robot_arg}, {adapter, []}, opts)
  end

  def start_robot(name, {robot, robot_arg}, {adapter, adapter_arg}, opts) do
    Clover.Robot.Supervisor.start_link({name, {robot, robot_arg}, {adapter, adapter_arg}}, opts)
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

  defp whereis_robot_supervisor(robot) do
    case whereis_robot(robot) do
      nil ->
        nil

      pid ->
        @robot_supervisor
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

  @doc false
  def format_error({:not_exported, {mod, function}}) do
    "#{mod} does not export function #{function}"
  end

  def format_error({:badarg, {mod, function, arg}}) do
    "bad argument for #{mod}.#{function}: #{inspect(arg)}"
  end

  def format_error({:unhandled_message, message}) do
    "unhandled message #{inspect(message)}"
  end

  def format_error(reason) do
    reason
  end
end
