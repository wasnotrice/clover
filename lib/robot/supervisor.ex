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
    {robot, robot_opts} = Keyword.pop(opts, :robot)

    if is_nil(robot) do
      raise "Missing :robot, got: #{inspect(opts)}"
    end

    children = [
      {robot, robot_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
