defmodule Clover.Robot.MessageWorker do
  @moduledoc """
  A worker for handling an individual message
  """

  use Task

  alias Clover.{
    Adapter,
    Message,
    MessageHandler,
    Robot
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

    message
    |> MessageHandler.handle_message(mention_format, robot_data, handlers)
    |> handle_response(message, name)
  end

  defp handle_response(handler_response, message, name) do
    # log(:debug, "handler response", inspect: handler_response)

    case handler_response do
      {action, %Message{} = reply} when action in [:say] ->
        Adapter.outgoing(name, action, reply)

      # Worker could send data update back to robot
      {action, %Message{} = reply, _new_data} when action in [:say] ->
        Adapter.outgoing(name, action, reply)

      {:typing, delay, {action, %Message{} = followup}}
      when action in [:say] and is_integer(delay) ->
        Adapter.outgoing(name, :typing, Map.put(message, :text, nil))
        Robot.outgoing_after(name, {action, followup}, delay)

      # Worker could send data update back to robot
      {:noreply, _new_data} ->
        :ok

      :noreply ->
        :ok

      :nomatch ->
        :ok

      bad_return ->
        log(:error, """
        invalid handler return #{inspect(bad_return)}")
        expected one of:
        {:say, %Message{}}
        {:say, %Message, data}
        {:typing, delay, [valid return]}
        {:noreply, data}
        :noreply
        :nomatch
        """)
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
