defmodule Clover.Test.TestAdapter do
  @moduledoc """
  A `Clover.Adapter` implementation for testing
  """

  use Clover.Adapter

  alias Clover.{
    Adapter,
    Message,
    User
  }

  @impl Clover.Adapter
  def init(opts, %{robot: robot} = state) do
    sink = Keyword.fetch!(opts, :sink)
    spawn(fn -> Adapter.connected(robot, %{me: %User{id: "testbot", name: "testbot"}}) end)
    {:ok, Map.merge(state, %{sink: sink})}
  end

  @impl Clover.Adapter
  @spec handle_in({:message, String.t()}, map, any()) :: {Message.t(), map}
  def handle_in({:message, text}, %{robot: robot} = state, _context) do
    message = %Message{
      robot: robot,
      text: text,
      user: %User{
        id: "test",
        name: "test"
      }
    }

    {message, state}
  end

  @impl Clover.Adapter
  def handle_out(%Message{action: action, text: text}, %{sink: sink}) when action in [:say] do
    Kernel.send(sink, {action, text})
  end

  def handle_out(%Message{action: action}, %{sink: sink}) when action in [:typing] do
    Kernel.send(sink, action)
  end

  @impl Clover.Adapter
  def mention_format(%User{name: name}), do: ~r/(#{name})/
end
