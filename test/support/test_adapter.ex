defmodule Hugh.Test.TestAdapter do
  use Hugh.Adapter

  alias Hugh.Robot

  def start_link(arg, opts \\ []) do
    arg = Keyword.put_new(arg, :sink, self())
    Hugh.Adapter.start_link(__MODULE__, arg, opts)
  end

  def init(arg) do
    {:ok, %{sink: Keyword.fetch!(arg, :sink)}}
  end

  def process_suffix, do: "TestAdapter"

  def handle_in({:message, message}, %{robot: robot} = state) do
    Kernel.send(robot, {:in, message})
    {:noreply, state}
  end

  def handle_out({:send, message}, %{sink: sink} = state) do
    Kernel.send(sink, {:out, message})
  end

  def handle_info({:incoming, message}, %{robot: robot} = state) do
    Robot.handle_in(robot, message)
    Kernel.send(robot, {:send, message})
    {:noreply, state}
  end

  def handle_info(message, state) do
    # IO.inspect(message, label: "adapter unhandled")
    {:noreply, state}
  end

  def handle_outgoing(message, state) do
    for receiver <- Map.get(state, :receivers, []) do
      Kernel.send(receiver, message)
    end
  end
end
