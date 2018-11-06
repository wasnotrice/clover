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
    message
    |> normalize(context)
    |> classify(context)
    |> handle_message(context)
    |> handle_response(context)
  end

  defp normalize(message, %{adapter: adapter} = context) do
    apply(adapter, :normalize, [message, context])
  end

  defp classify(%Message{halted?: true} = message, _), do: message

  defp classify(message, %{adapter: adapter} = context) do
    if function_exported?(adapter, :classify, 2) do
      apply(adapter, :classify, [message, context])
    else
      message
    end
  end

  defp handle_message(%Message{} = message, context) do
    message
    |> find_or_start_conversation(context)
    |> Conversation.incoming(message)
  end

  defp find_or_start_conversation(message, %{robot: robot}) do
    case Clover.whereis_conversation(message) do
      nil ->
        {:ok, conversation} = Conversation.start(message, robot)
        conversation

      conversation ->
        conversation
    end
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
