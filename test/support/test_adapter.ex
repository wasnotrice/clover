defmodule Hugh.Test.TestAdapter do
  use Hugh.Adapter

  alias Hugh.{
    Message
  }

  def start_link({robot, adapter_opts}, opts \\ []) do
    Hugh.Adapter.start_link(__MODULE__, {robot, adapter_opts}, opts)
  end

  def init(opts, state) do
    sink = Keyword.fetch!(opts, :sink)
    {:ok, Map.merge(state, %{sink: sink})}
  end

  @impl Hugh.Adapter
  def process_suffix, do: "TestAdapter"

  @impl Hugh.Adapter
  def handle_in({:message, text}, %{robot: robot} = state, _context) do
    message = %Message{
      robot: robot,
      text: text
    }

    {:ok, message, state}
  end

  @impl Hugh.Adapter

  def handle_out({:send, %Message{text: text}}, %{sink: sink}) do
    Kernel.send(sink, {:out, text})
  end

  def handle_out({:send, message}, %{sink: sink}) do
    Kernel.send(sink, {:out, message})
  end
end
