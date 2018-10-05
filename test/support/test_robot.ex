defmodule Hugh.Test.TestRobot do
  use Hugh.Robot

  alias Hugh.Adapter

  def init(_arg) do
    {:ok, %{}}
  end

  def start_link(arg, opts \\ []) do
    Hugh.Robot.start_link(__MODULE__, arg, opts)
  end

  def handle_message(message, data) do
    response =
      case message do
        "ping" -> {:send, "pong"}
        message -> {:send, message}
      end

    {:reply, response, data}
  end

  def handle_event(:enter, :disconnected, :disconnected, _data) do
    :keep_state_and_data
  end

  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end
end
