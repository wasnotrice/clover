defmodule Clover.Robot.MessageWorker do
  @moduledoc """
  A worker for handling an individual message
  """

  use Task

  alias Clover.{
    Adapter,
    Message,
    Script,
    Robot
  }

  alias Clover.Util.Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run({name, robot_mod, robot_data, raw_message}) do
    handlers =
      if function_exported?(robot_mod, :scripts, 0),
        do: robot_mod.scripts(),
        else: []

    me = Map.get(robot_data, :me)
    adapter = Map.fetch!(robot_data, :adapter)
    mention_format = apply(adapter, :mention_format, [me])

    message =
      raw_message
      |> normalize(adapter, robot_data)
      |> classify(adapter, robot_data)
      |> Script.handle_message(mention_format, robot_data, handlers)
      |> handle_response(name)

    # |> Robot.assign_to_conversation_or_hear_new_message_or_handle_non_message_event(robot_mod)
    # |> Script.run_through_script()
    # |> Adapter.send(adapter_mod)
    # |> Adapter.format(adapter_mod)
  end

  def normalize(%Message{halted?: true} = message, _, _), do: message

  def normalize(message, mod, context) do
    apply(mod, :normalize, [message, context])
  end

  def classify(%Message{halted?: true} = message, _, _), do: message

  def classify(message, mod, context) do
    apply(mod, :classify, [message, context])
  end

  defp handle_response(handler_response, name) do
    log(:debug, "handle_response/2", inspect: handler_response)

    case handler_response do
      %Message{} = reply ->
        dispatch(name, reply)

      # Worker could send data update back to robot
      {%Message{} = reply, _new_data} ->
        dispatch(name, reply)

      messages when is_list(messages) ->
        Enum.each(messages, &dispatch(name, &1))

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
