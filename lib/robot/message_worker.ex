defmodule Clover.Robot.MessageWorker do
  @moduledoc """
  A worker that handles an individual message
  """

  use Task

  alias Clover.{
    Adapter,
    Conversation,
    Message,
    Robot
  }

  alias Clover.Util.Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run({message, context}) do
    %{adapter: adapter, name: name, robot: robot} = context

    message
    |> normalize(adapter, context)
    |> classify(adapter, context)
    |> assign_conversation()
    |> handle_message(context)
    |> handle_response(context)
  end

  defp normalize(message, mod, context) do
    apply(mod, :normalize, [message, context])
  end

  defp classify(%Message{halted?: true} = message, _, _), do: message

  defp classify(message, mod, context) do
    if function_exported?(mod, :classify, 2) do
      apply(mod, :classify, [message, context])
    else
      message
    end
  end

  defp assign_conversation(message) do
    Message.put_conversation(message, Clover.whereis_conversation(message))
  end

  defp handle_message(%Message{conversation: nil} = message, %{robot: robot} = context) do
    {:ok, conversation} = Conversation.start(message, robot)

    message
    |> Message.put_conversation(conversation)
    |> handle_message(context)
  end

  defp handle_message(%Message{conversation: conversation} = message, _context) do
    Conversation.incoming(conversation, message)
  end

  defp handle_response(response, %{name: robot}) do
    log(:debug, "handle_response/2", inspect: response)

    case response do
      %Message{} = reply ->
        dispatch(robot, reply)

      # Worker could send data update back to robot
      {%Message{} = reply, _new_data} ->
        dispatch(robot, reply)

      messages when is_list(messages) ->
        Enum.each(messages, &dispatch(robot, &1))

      _ ->
        :ok
    end
  end

  # Delayed messages routed through robot
  def dispatch(name, %Message{delay: delay} = message) when is_integer(delay) do
    Robot.outgoing(name, message)
  end

  def dispatch(name, message) do
    Adapter.outgoing(name, message)
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

  defp log(level, message, opts) do
    Logger.log(level, "message worker", message, opts)
  end
end
