defmodule Clover.Test.TestRobot do
  use Clover.Robot

  alias Clover.{
    MessageHandler
  }

  def init(_arg, data) do
    {:ok, data}
  end

  def start_link(arg, opts \\ []) do
    Clover.Robot.start_link(__MODULE__, arg, opts)
  end

  def handle_connected(connection_state, data) do
    log(:debug, "connected", inspect: connection_state)
    {:ok, data}
  end

  def message_handlers do
    [
      pong(),
      echo()
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

  defp echo do
    %MessageHandler{
      match: ~r/.*/,
      respond: fn message, data ->
        {:send, message, data}
      end
    }
  end

  defp log(level, message, opts) do
    Clover.Util.Logger.log(level, "test robot", message, opts)
  end
end
