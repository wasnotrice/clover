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
  def init(_opts) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec whereis_adapter(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: pid() | nil
  def whereis_adapter(supervisor), do: find_child(supervisor, @adapter_id)

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
