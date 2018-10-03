defmodule Hugh.Test.TestRobot do
  use Hugh.Robot

  alias Hugh.Adapter

  def handle_event(:enter, :disconnected, :disconnected, _data) do
    :keep_state_and_data
  end

  def handle_event(:cast, {:send, message}, _state, %{adapter: adapter}) do
    Adapter.send(adapter, message)
    :keep_state_and_data
  end

  def handle_event(type, event, _state, _data) do
    IO.inspect(%{type: type, event: event}, label: "test robot received")
    :keep_state_and_data
  end
end
