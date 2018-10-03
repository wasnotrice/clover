defmodule Hugh.Test.TestAdapter do
  use Hugh.Adapter

  alias Hugh.Robot

  def process_suffix, do: "TestAdapter"

  @doc """
  Add an additional message receiver.

  Useful for receiving messages in tests
  """
  def add_receiver(pid, receiver) do
    GenServer.cast(pid, {:add_receiver, receiver})
  end

  def handle_cast({:add_receiver, receiver}, state) do
    receivers = Map.get(state, :receivers, [])
    {:noreply, Map.put(state, :receivers, [receiver | receivers])}
  end

  def handle_cast({:send, message}, state) do
    handle_outgoing({:send, message}, state)
    {:noreply, state}
  end

  def handle_info({:incoming, message}, %{robot: robot} = state) do
    Robot.handle_in(robot, message)
    Kernel.send(robot, {:send, message})
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "adapter unhandled")
    {:noreply, state}
  end

  def handle_outgoing(message, state) do
    for receiver <- Map.get(state, :receivers, []) do
      Kernel.send(receiver, message)
    end
  end
end
