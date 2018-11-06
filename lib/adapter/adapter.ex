defmodule Clover.Adapter do
  @moduledoc """
  A Behaviour for `Clover` chat platform adapters.
  """
  use GenServer

  alias Clover.{
    Message,
    Robot
  }

  alias Clover.Robot.MessageSupervisor

  @type context :: map
  @type state :: map

  @doc """
  Handler for incoming messages

  The `message` will be whatever was passed to Adapter.incoming. This will depend on the adapter.
  """
  @callback handle_in({:message, any()}, state, context) :: {Message.t(), state}
  @callback handle_out(message :: Message.t(), state) :: {Message.t(), state}
  @callback init(arg :: any, state) :: {:ok, state()}

  @doc """
  Converts a raw incoming message into a `Clover.Message` struct
  """
  @callback normalize({:message, any()}, context) :: Message.t()

  @doc """
  Classifies an incoming message by message type
  """
  @callback classify(Message.t(), context) :: Message.t()

  @doc """
  A regex for detecting any mention in message text. Optional.
  """
  @callback mention_format() :: Regex.t()

  @doc """
  A regex for detecting a mention of `user` in message text. Required.
  """
  @callback mention_format(user :: Clover.User.t()) :: Regex.t()

  @optional_callbacks [
    init: 2,
    mention_format: 0,
    normalize: 2
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Adapter
    end
  end

  @doc false
  def child_spec(arg, opts \\ []) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg, opts]}
    }

    Supervisor.child_spec(default, [])
  end

  def start_link(arg, opts) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  @doc false
  def init({robot, robot_mod, mod, arg}) do
    cond do
      !function_exported?(mod, :handle_in, 3) ->
        {:stop, {:undef, mod, handle_in: 3}}

      !function_exported?(mod, :handle_out, 2) ->
        {:stop, {:undef, mod, handle_out: 2}}

      !function_exported?(mod, :normalize, 2) ->
        {:stop, {:undef, mod, normalize: 2}}

      true ->
        []

        state = %{
          mod: mod,
          robot: robot,
          robot_mod: robot_mod
        }

        if function_exported?(mod, :init, 2) do
          mod.init(arg, state)
        else
          {:ok, state}
        end
    end
  end

  def connected(robot_name, state) do
    call(robot_name, {:connected, state})
  end

  def outgoing(robot_name, message) do
    cast(robot_name, {:outgoing, message})
  end

  def incoming(robot_name, message, context) do
    cast(robot_name, {:incoming, {:message, message}, context})
  end

  def mention_format(robot_name) do
    call(robot_name, {:mention_format})
  end

  def mention_format(robot_name, user) do
    call(robot_name, {:mention_format, user})
  end

  defp call(robot_name, message) do
    robot_name
    |> Clover.whereis_robot_adapter()
    |> GenServer.call(message)
  end

  defp cast(robot_name, message) do
    robot_name
    |> Clover.whereis_robot_adapter()
    |> GenServer.cast(message)
  end

  def via_tuple(robot_name) do
    {:via, Registry, {Clover.registry(), {robot_name, :adapter}}}
  end

  @doc false
  def handle_call({:connected, connection_state}, _from, %{robot: robot} = state) do
    log(:debug, "connected", inspect: connection_state)
    Robot.connected(robot, connection_state)
    {:reply, :ok, Map.put(state, :me, Map.fetch!(connection_state, :me))}
  end

  @doc false
  def handle_call(:mention_format, _from, %{mod: mod} = state) do
    format =
      if function_exported?(mod, :mention_format, 0),
        do: mod.mention_format(),
        else: nil

    {:reply, format, state}
  end

  @doc false
  def handle_call({:mention_format, user}, _from, %{mod: mod} = state) do
    format = mod.mention_format(user)
    {:reply, format, state}
  end

  @doc false
  def handle_cast(
        {:incoming, {:message, message}, context},
        %{mod: mod, robot: robot, robot_mod: robot_mod, me: me} = state
      ) do
    log(:debug, "incoming", inspect: {message, state})

    adapter_context = %{
      adapter_mod: mod,
      robot_mod: robot_mod,
      adapter_context: Map.put(context, :me, me)
    }

    {:ok, _worker} = MessageSupervisor.dispatch(robot, message, adapter_context)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:outgoing, message}, %{mod: mod} = state) do
    if function_exported?(mod, :handle_out, 2) do
      log(:debug, "Adapter calling #{mod}.handle_out({#{inspect(message)}}, #{inspect(state)})")
      mod.handle_out(message, state)
      {:noreply, state}
    else
      log(:warn, Clover.format_error({:not_exported, {mod, :handle_out, 2}}))
      {:noreply, state}
    end
  end

  defp log(level, message, opts \\ []) do
    alias Clover.Util.Logger
    Logger.log(level, "adapter", message, opts)
  end
end
