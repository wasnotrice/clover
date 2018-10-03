defmodule Hugh.Robot.TestRobot do
  use Hugh.Robot

  def handle_event(:enter, :disconnected, :disconnected, _data) do
    :keep_state_and_data
  end
end
