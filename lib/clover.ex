defmodule Clover do
  @moduledoc """
  The Clover application
  """

  use Application

  alias Clover.{
    Adapter,
    Conversation,
    Message,
    Robot
  }

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

  def whereis_conversation(message) do
    whereis(Conversation.via_tuple(message))
  end

  def whereis_robot(robot) do
    whereis(Robot.via_tuple(robot))
  end

  def whereis_robot_adapter(robot) do
    whereis(Adapter.via_tuple(robot))
  end

  defp whereis({:via, _, {_, key}}) do
    case Registry.lookup(@registry, key) do
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
  def format_error({:not_exported, {mod, function, arity}}) do
    "#{mod} does not export function #{function}/#{arity}"
  end

  def format_error({:invalid_option, {{mod, function, arity}, option, valid}}) do
    """
    invalid option for #{mod}.#{function}/#{arity} #{inspect(option)}
    valid options: #{inspect(valid)}
    """
  end

  def format_error({:unhandled_message, message}) do
    "unhandled message #{inspect(message)}"
  end

  def format_error({:invalid_script_return, invalid_return}) do
    """
    invalid script return #{inspect(invalid_return)}")
    expected one of:
      %Message{action: :say | :typing}
      {%Message{action: :say | :typing}, data}
      [%Message{action: :say | :typing}]
      {:noreply, data}
      :noreply
      :nomatch
    """
  end

  def format_error(reason) do
    "unexpected error #{inspect(reason)}"
  end
end
