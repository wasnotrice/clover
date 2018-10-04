defmodule Hugh.RobotSupervisor do
  @moduledoc """
  Supervises all of the robots
  """
  use DynamicSupervisor

  @name Hugh.Robots

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: @name)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
