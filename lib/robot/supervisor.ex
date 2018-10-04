defmodule Hugh.Robot.Supervisor do
  @moduledoc """
  Supervises the processes of a single robot
  """
  use Supervisor

  @behaviour Hugh.Robot.Glue

  alias Hugh.Robot.Glue

  @robot_id :robot
  @adapter_id :adapter

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {robot_mod, _} = Glue.module_and_pid(opts, :robot)
    {adapter_mod, _} = Glue.module_and_pid(opts, :adapter)

    robot_opts =
      opts
      |> Keyword.put_new(:name, robot_mod)
      |> Keyword.put(:glue, {__MODULE__, self()})

    children = [
      Supervisor.child_spec({robot_mod, robot_opts}, id: @robot_id),
      Supervisor.child_spec({adapter_mod, robot_opts}, id: @adapter_id)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @impl true
  @spec whereis_adapter(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: pid() | nil
  def whereis_adapter(supervisor), do: find_child(supervisor, @adapter_id)

  @impl true
  @spec whereis_robot(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: pid() | nil
  def whereis_robot(supervisor), do: find_child(supervisor, @robot_id)

  defp find_child(supervisor, id) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find(fn {child_id, _, _, _} -> child_id == id end)
    |> case do
      nil -> nil
      {_, pid, _, _} -> pid
    end
  end
end
