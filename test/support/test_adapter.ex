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

  def start_link({robot, adapter_opts}, opts \\ []) do
    Adapter.start_link(__MODULE__, {robot, adapter_opts}, opts)
  end

  def init(opts, %{robot: robot} = state) do
    sink = Keyword.fetch!(opts, :sink)
    spawn(fn -> Adapter.connected(robot, %{me: %User{id: "test", name: "test"}}) end)
    {:ok, Map.merge(state, %{sink: sink})}
  end

  @impl Clover.Adapter
  @spec handle_in({:message, String.t()}, map, any()) :: {:message, Message.t(), map}
  def handle_in({:message, text}, %{robot: robot} = state, _context) do
    message = %Message{
      robot: robot,
      text: text,
      user: %User{
        id: "test",
        name: "test"
      }
    }

    {:message, message, state}
  end

  @impl Clover.Adapter

  def handle_out({:send, %Message{text: text}}, %{sink: sink}) do
    Kernel.send(sink, {:out, text})
  end

  def handle_out({:send, message}, %{sink: sink}) do
    Kernel.send(sink, {:out, message})
  end
end
