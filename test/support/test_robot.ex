defmodule Hugh.Test.TestRobot do
  use Hugh.Robot

  alias Hugh.Message

  def init(_arg) do
    handlers = [
      fn %Message{text: text} = message, data ->
        case String.trim(text) do
          "ping" -> {:reply, {:send, Map.put(message, :text, "pong")}, data}
          _ -> {:noreply, data}
        end
      end,
      fn message, data ->
        {:reply, {:send, message}, data}
      end
    ]

    {:ok, %{handlers: handlers}}
  end

  def start_link(arg, opts \\ []) do
    Hugh.Robot.start_link(__MODULE__, arg, opts)
  end
end
