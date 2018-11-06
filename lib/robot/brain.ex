defmodule Clover.Robot.Brain do
  @moduledoc """
  Functions for interacting with the robot key-value brain
  """
  alias Clover.{
    Message,
    Robot
  }

  def put(message, key, value) do
    message
    |> Message.robot()
    |> Robot.put_assign(key, value)
  end

  def get(message, key) do
    message
    |> Message.robot()
    |> Robot.get_assign(key)
  end
end
