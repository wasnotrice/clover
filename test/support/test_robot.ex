defmodule Hugh.Test.TestRobot do
  use Hugh.Robot

  alias Hugh.{
    MessageHandler
  }

  def init(_arg) do
    {:ok, %{}}
  end

  def start_link(arg, opts \\ []) do
    Hugh.Robot.start_link(__MODULE__, arg, opts)
  end

  def handle_connected(connection_state, data) do
    log(:debug, "connected", inspect: connection_state)
    {:ok, data}
  end

  def message_handlers do
    [
      pong(),
      fn message, data ->
        {:reply, {:send, message}, data}
      end
    ]
  end

  defp pong do
    %MessageHandler{
      match: ~r/^ping$/,
      respond: fn message, data ->
        {:send, Map.put(message, :text, "pong"), data}
      end
    }
  end

  defp log(level, message, opts) do
    Hugh.Util.Logger.log(level, "test robot", message, opts)
  end
end
