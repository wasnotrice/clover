defmodule Clover.Test.TestRobot do
  @moduledoc """
  A `Clover.Robot` implementation for testing
  """

  use Clover.Robot

  alias Clover.{
    MessageHandler,
    Robot
  }

  def init(_arg, data) do
    {:ok, data}
  end

  def start_link(arg, opts \\ []) do
    Robot.start_link(__MODULE__, arg, opts)
  end

  def handle_connected(connection_state, data) do
    log(:debug, "connected", inspect: connection_state)
    {:ok, data}
  end

  def message_handlers do
    [
      pong(),
      pid(),
      crash(),
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

  defp pid do
    %MessageHandler{
      match: ~r/^pid$/,
      respond: fn message, data ->
        {:send, Map.put(message, :text, inspect(self())), data}
      end
    }
  end

  defp crash do
    %MessageHandler{
      match: ~r/^crash$/,
      respond: fn _message, _data ->
        raise "CRASH!"
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
    alias Clover.Util.Logger
    Logger.log(level, "test robot", message, opts)
  end
end
