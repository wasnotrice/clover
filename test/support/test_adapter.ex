defmodule Clover.Test.TestAdapter do
  @moduledoc """
  A `Clover.Adapter` implementation for testing
  """

  use Clover.Adapter

  alias Clover.{
    Message,
    Robot,
    User
  }

  @impl Clover.Adapter
  def init(opts, %{robot: robot} = state) do
    sink = Keyword.fetch!(opts, :sink)
    spawn(fn -> Robot.connected(robot, %{me: %User{id: "testbot", name: "testbot"}}) end)
    {:ok, Map.merge(state, %{sink: sink})}
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

  @impl Clover.Adapter
  def normalize(text, %{me: me, name: name}) do
    Message.new(%{
      me: me,
      mention_format_any: nil,
      mention_format_me: mention_format(me),
      robot: name,
      text: text,
      user: %User{
        id: "test",
        name: "test"
      }
    })
  end

  @impl Clover.Adapter
  def classify(%Message{} = message, _context), do: message
end
