defmodule Clover.Test.TestRobot do
  @moduledoc """
  A `Clover.Robot` implementation for testing
  """

  use Clover.Robot

  alias Clover.{
    MessageHandler
  }

  def init(_arg, data) do
    {:ok, data}
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
      bad_return(),
      echo()
    ]
  end

  defp pong do
    %MessageHandler{
      match: ~r/^ping$/,
      respond: fn message, _data ->
        {:send, Map.put(message, :text, "pong")}
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

  # Returns an invalid value
  defp bad_return do
    %MessageHandler{
      match: ~r/^bad return$/,
      respond: fn message, _data ->
        {:invalid_tag, Map.put(message, :text, "oops!")}
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
