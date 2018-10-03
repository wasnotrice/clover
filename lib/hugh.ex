defmodule Hugh do
  @moduledoc """
  Documentation for Hugh.
  """

  use Application

  def start(_type, _args) do
    Hugh.Supervisor.start_link(name: Hugh.App)
  end

  def start_robot(mod, opts \\ []) do
    Hugh.RobotSupervisor.start_child(mod, opts)
  end

  def format_error(reason) do
    reason
  end
end
