defmodule Clover.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(robot_supervisor, opts) do
    Supervisor.start_link(__MODULE__, robot_supervisor, opts)
  end

  def init(robot_supervisor) do
    children = [
      {Registry, keys: :unique, name: Clover.Registry},
      {DynamicSupervisor, name: robot_supervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
