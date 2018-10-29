defmodule Clover.Test.Hexadecimal do
  @moduledoc """
  A module-style script for testing
  """

  use Clover.Robot

  respond ~r/^hex encode (.*)/i, message, match, _data do
    source =
      match
      |> Map.get(:captures)
      |> Enum.at(1)

    try do
      encoded =
        source
        |> String.to_integer()
        |> Integer.to_string(16)

      say(message, encoded)
    rescue
      ArgumentError ->
        say(message, ~s(I can't decode "#{source}". Is it an integer?))
    end
  end

  respond ~r/^hex decode (.*)/i, message, match, _data do
    source =
      match
      |> Map.get(:captures)
      |> Enum.at(1)

    try do
      decoded =
        source
        |> String.to_integer(16)
        |> Integer.to_string()

      say(message, decoded)
    rescue
      ArgumentError ->
        say(message, ~s(I can't decode "#{source}". Is it a hex string?))
    end
  end
end
