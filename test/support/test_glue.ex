defmodule Hugh.Test.TestGlue do
  @behaviour Hugh.Robot.Glue

  # In the test environment, always direct the adapter and the robot to
  # message the process that started them
  @impl true
  def whereis_adapter(pid), do: pid

  @impl true
  def whereis_robot(pid), do: pid
end
