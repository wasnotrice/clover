defmodule Clover.Test.TestHandler do
  @moduledoc """
  A module-style handler for testing
  """

  use Clover.Robot

  respond ~r/^hex encode (.*)/i, message, match, _data do
    try do
      encoded =
        match
        |> Map.get(:captures)
        |> Enum.at(1)
        |> String.to_integer()
        |> Integer.to_string(16)

      say(message, encoded)
    rescue
      ArgumentError ->
        say(message, "I can only convert integers")
    end
  end
end
