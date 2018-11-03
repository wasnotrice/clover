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

  def run({name, robot_mod, robot_data, message}) do
    handlers =
      if function_exported?(robot_mod, :scripts, 0),
        do: robot_mod.scripts(),
        else: []

    me = Map.get(robot_data, :me)
    mention_format = Adapter.mention_format(name, me)

    message
    |> Script.handle_message(mention_format, robot_data, handlers)
    |> handle_response(name)
  end

  def run(
        {name, raw_message, %{adapter_mod: adapter, robot_mod: robot, adapter_context: context}}
      ) do
    context =
      context
      |> Map.put(:robot, name)

    message =
      raw_message
      |> normalize(adapter, context)
      |> classify(adapter, context)

    # |> Robot.assign_to_conversation_or_hear_new_message_or_handle_non_message_event(robot_mod)

    run({name, robot, %{me: Map.fetch!(context, :me)}, message})

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

    # if function_exported?(mod, :handle_in, 3) do
    #   case mod.handle_in({:message, message}, state, context) do
    #     {message, state} ->
    #       log(:debug, "handled message", inspect: message)
    #       Robot.incoming(robot, message)
    #       {:noreply, state}

    #     _ ->
    #       log(:error, Clover.format_error({:unhandled_message, message}))
    #   end
    # else
    #   log(:error, Clover.format_error({:not_exported, {mod, :handle_in, 2}}))
    #   {:noreply, state}
    # end
  end

  def incoming() do
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
