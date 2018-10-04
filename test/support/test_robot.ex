defmodule Hugh.Test.TestRobot do
  use Hugh.Robot

  alias Hugh.Adapter

  def init(_arg) do
    {:ok, %{}}
  end

  def start_link(arg, opts \\ []) do
    Hugh.Robot.start_link(__MODULE__, arg, opts)
  end

  def handle_event(:enter, :disconnected, :disconnected, _data) do
    :keep_state_and_data
  end

  def handle_event(type, event, _state, _data) do
    # IO.inspect(%{type: type, event: event}, label: "test robot received")
    :keep_state_and_data
  end
end
