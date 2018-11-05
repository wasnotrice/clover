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

  def run({message, %{robot: robot}}) do
    scripts = Robot.scripts(robot)
    robot = Message.robot(message)

    message
    |> assign_conversation()
    |> handle_message(scripts)
    |> handle_response(robot)
  end

  defp assign_conversation(message) do
    Message.put_conversation(message, Clover.whereis_conversation(message))
  end

  defp handle_message(%Message{conversation: nil} = message, scripts) do
    {:ok, conversation} = Conversation.start(message)

    message
    |> Message.put_conversation(conversation)
    |> handle_message(scripts)
  end

  defp handle_message(%Message{} = message, scripts) do
    Conversation.incoming(message, scripts)
  end

  defp handle_response(response, robot) do
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
