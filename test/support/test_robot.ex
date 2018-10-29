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

  respond ~r/^pid$/, :pid_script
  respond ~r/^bad return$/, :bad_return_script
  respond ~r/^bad return$/, :bad_return_rescue
  respond ~r/^crash$/, :crash_script
  respond ~r/^echo\s+(?<text>.*)$/, :echo_script
  respond ~r/ping/, :ping_script

  # A module-based script
  script(Clover.Test.Hexadecimal)

  respond ~r/^what time is it/i, message, _match, _data do
    say(message, "4:30")
  end

  respond ~r/^type\s+(?<text>.*)$/, :type_script
  respond ~r/^quicktype\s+(?<text>.*)$/, :quick_type_script

  overhear ~r/\bhello|hi|good morning\b/i, :greeting_script

  overhear ~r/^what day is it/i, message, _match, _data do
    say(message, "Every day is like Sunday")
  end

  # Scripts

  def ping_script(message, _match, _data) do
    say(message, "pong")
  end

  def pid_script(message, _match, _data) do
    say(message, inspect(self()))
  end

  def greeting_script(message, _match, _data) do
    say(message, "hi")
  end

  def crash_script(_message, _match, _data) do
    raise "CRASH!"
  end

  # Returns an invalid value
  def bad_return_script(message, _match, _data) do
    message
    |> Map.put(:action, :invalid_action)
    |> Map.put(:text, "oops!")
  end

  def bad_return_rescue(message, _match, _data) do
    say(message, "rescued bad return")
  end

  def echo_script(message, %{named_captures: %{"text" => text}}, data) do
    {say(message, text), data}
  end

  def type_script(message, %{named_captures: %{"text" => text}}, _data) do
    [
      message |> typing(),
      message |> say(text, delay: 1500)
    ]
  end

  def quick_type_script(message, %{named_captures: %{"text" => text}}, _data) do
    [
      message |> typing(),
      message |> say(text, delay: 10)
    ]
  end

  defp log(level, message, opts) do
    alias Clover.Util.Logger
    Logger.log(level, "test robot", message, opts)
  end
end
