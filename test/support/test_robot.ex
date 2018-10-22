defmodule Clover.Test.TestRobot do
  @moduledoc """
  A `Clover.Robot` implementation for testing
  """

  use Clover.Robot

  def init(_arg, data) do
    {:ok, data}
  end

  def handle_connected(connection_state, data) do
    log(:debug, "connected", inspect: connection_state)
    {:ok, data}
  end

  respond(~r/^pid$/, :pid_handler)
  overhear(~r/hello|hi|good morning/i, :greeting_handler)
  respond(~r/^bad return$/, :bad_return_handler)
  respond(~r/^crash$/, :crash_handler)
  respond(~r/^echo\s+(?<text>.*)$/, :echo_handler)
  respond(~r/ping/, :ping_handler)

  respond(~r/^what time is it/i, message, _match, _data) do
    {:send, Map.put(message, :text, "4:30")}
  end

  overhear(~r/^what day is it/i, message, _match, _data) do
    {:send, Map.put(message, :text, "Every day is like Sunday")}
  end

  def ping_handler(message, _match, _data) do
    {:send, Map.put(message, :text, "pong")}
  end

  def pid_handler(message, _match, _data) do
    {:send, Map.put(message, :text, inspect(self()))}
  end

  def greeting_handler(message, _match, _data) do
    {:send, Map.put(message, :text, "hi")}
  end

  def crash_handler(_message, _match, _data) do
    raise "CRASH!"
  end

  # Returns an invalid value
  def bad_return_handler(message, _match, _data) do
    {:invalid_tag, Map.put(message, :text, "oops!")}
  end

  def echo_handler(message, %{named_captures: %{"text" => text}}, data) do
    {:send, Map.put(message, :text, text), data}
  end

  defp log(level, message, opts) do
    alias Clover.Util.Logger
    Logger.log(level, "test robot", message, opts)
  end
end
