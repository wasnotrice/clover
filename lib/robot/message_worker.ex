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

    case handle_message(message, robot_data, handlers) do
      {:send, message} ->
        Adapter.send(name, message)

      # Worker could send data update back to robot
      {:send, message, _new_data} ->
        Adapter.send(name, message)

      # Worker could send data update back to robot
      {:noreply, _new_data} ->
        :ok

      :noreply ->
        :ok
    end
  end

  @spec handle_message(Message.t(), map, [MessageHandler.t()]) ::
          {:send, Message.t()} | {:send, Message.t(), map} | {:noreply, map} | :noreply
  defp handle_message(_message, _data, []), do: :noreply

  defp handle_message(message, data, [handler | tail]) do
    case MessageHandler.handle(handler, message, data) do
      {:noreply, data} ->
        {:noreply, data}

      {mode, %Message{} = message} when mode in [:send] ->
        {mode, message}

      {mode, %Message{} = message, data} when mode in [:send] ->
        {mode, message, data}

      :nomatch ->
        handle_message(message, data, tail)

      bad_return ->
        log(:error, """
        invalid handler return #{inspect(bad_return)}")
        expected {:send, %Message{}} | {:send, %Message, data} | {:noreply, data} | :nomatch
        """)

        handle_message(message, data, tail)
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
