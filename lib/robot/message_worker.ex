defmodule Clover.Robot.MessageWorker do
  @moduledoc """
  A worker for handling an individual message
  """

  use Task

  alias Clover.{
    Adapter,
    Message,
    MessageHandler
  }

  alias Clover.Util.Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run({name, robot_mod, robot_data, message}) do
    handlers =
      if function_exported?(robot_mod, :message_handlers, 0),
        do: robot_mod.message_handlers(),
        else: []

    me = Map.get(robot_data, :me)
    mention_format = Adapter.mention_format(name, me)

    case handle_message(message, mention_format, robot_data, handlers) do
      {:send, reply} ->
        Adapter.send(name, reply)

      # Worker could send data update back to robot
      {:send, reply, _new_data} ->
        Adapter.send(name, reply)

      # Worker could send data update back to robot
      {:noreply, _new_data} ->
        :ok

      :noreply ->
        :ok

      :nomatch ->
        :ok
    end
  end

  # Descends into the list of handlers, attempting to match the last handler first, to preserve the order in which
  # handlers were declared
  @spec handle_message(Message.t(), mention_format :: Regex.t(), data :: map, [
          MessageHandler.t()
        ]) ::
          {MessageHandler.respond_mode(), Message.t()}
          | {MessageHandler.respond_mode(), Message.t(), map}
          | {:noreply, map}
          | :noreply
          | :nomatch
  defp handle_message(_message, _mention_format, _data, []), do: :noreply

  defp handle_message(message, mention_format, data, [handler | []]),
    do: MessageHandler.handle(handler, message, mention_format, data)

  defp handle_message(message, mention_format, data, [handler | tail]) do
    case handle_message(message, mention_format, data, tail) do
      :noreply ->
        {:noreply, data}

      {:noreply, data} ->
        {:noreply, data}

      {mode, %Message{} = message} when mode in [:send] ->
        {mode, message}

      {mode, %Message{} = message, data} when mode in [:send] ->
        {mode, message, data}

      :nomatch ->
        MessageHandler.handle(handler, message, mention_format, data)

      bad_return ->
        log(:error, """
        invalid handler return #{inspect(bad_return)}")
        expected {:send, %Message{}} | {:send, %Message, data} | {:noreply, data} | :noreply | :nomatch
        """)

        MessageHandler.handle(handler, message, mention_format, data)
    end
  end

  @doc false
  def child_spec(arg, opts \\ []) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]},
      restart: :transient
    }

    Supervisor.child_spec(default, opts)
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, "message worker", message, opts)
  end
end
