defmodule Hugh.Test.TestAdapter do
  use Hugh.Adapter

  alias Hugh.Robot

  def process_suffix, do: "TestAdapter"

  def handle_cast({:send, message}, %{robot: robot} = state) do
    Kernel.send(robot, {:message, message})
    {:noreply, state}
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
