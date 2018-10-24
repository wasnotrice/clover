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
  respond(~r/^bad return$/, :bad_return_handler)
  respond(~r/^crash$/, :crash_handler)
  respond(~r/^echo\s+(?<text>.*)$/, :echo_handler)
  respond(~r/ping/, :ping_handler)

  respond(~r/^what time is it/i, message, _match, _data) do
    {:say, Map.put(message, :text, "4:30")}
  end

  respond(~r/^type\s+(?<text>.*)$/, :type_handler)
  respond(~r/^quicktype\s+(?<text>.*)$/, :quick_type_handler)

  overhear(~r/\bhello|hi|good morning\b/i, :greeting_handler)

  overhear(~r/^what day is it/i, message, _match, _data) do
    {:say, Map.put(message, :text, "Every day is like Sunday")}
  end

  def ping_handler(message, _match, _data) do
    {:say, Map.put(message, :text, "pong")}
  end

  def pid_handler(message, _match, _data) do
    {:say, Map.put(message, :text, inspect(self()))}
  end

  def greeting_handler(message, _match, _data) do
    {:say, Map.put(message, :text, "hi")}
  end

  def crash_handler(_message, _match, _data) do
    raise "CRASH!"
  end

  # Returns an invalid value
  def bad_return_handler(message, _match, _data) do
    {:invalid_action, Map.put(message, :text, "oops!")}
  end

  def echo_handler(message, %{named_captures: %{"text" => text}}, data) do
    {:say, Map.put(message, :text, text), data}
  end

  def type_handler(message, %{named_captures: %{"text" => text}}, _data) do
    {:typing, 1500, {:say, Map.put(message, :text, text)}}
  end

  def quick_type_handler(message, %{named_captures: %{"text" => text}}, _data) do
    {:typing, 10, {:say, Map.put(message, :text, text)}}
  end

  defp log(level, message, opts) do
    alias Clover.Util.Logger
    Logger.log(level, "test robot", message, opts)
  end
end
