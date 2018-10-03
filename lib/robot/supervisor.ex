defmodule Hugh.Robot.Supervisor do
  @moduledoc """
  Supervises the processes of a single robot
  """
  use Supervisor

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

    children = [
      {robot, robot_opts},
      {adapter, robot_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
