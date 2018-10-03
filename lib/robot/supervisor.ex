defmodule Hugh.Robot.Supervisor do
  @moduledoc """
  Supervises the processes of a single robot
  """
  use Supervisor

  @robot_id :robot
  @adapter_id :adapter

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    robot = Keyword.fetch!(opts, :robot)
    adapter = Keyword.fetch!(opts, :adapter)

    robot_opts =
      Keyword.drop(opts, [:robot, :adapter])
      |> Keyword.put_new(:name, robot)
      |> Keyword.put(:supervisor, self())

    children = [
      Supervisor.child_spec({robot, robot_opts}, id: @robot_id),
      Supervisor.child_spec({adapter, robot_opts}, id: @adapter_id)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def find_adapter(supervisor), do: find_child(supervisor, @adapter_id)
  def find_robot(supervisor), do: find_child(supervisor, @robot_id)

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
