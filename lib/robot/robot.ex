defmodule Clover.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @callback handle_connected(connection_state :: map, data :: data()) ::
              {:ok, data()} | {:error, Clover.Error}
  @callback init(arg :: any, data :: any) :: GenServer.on_start()
  @callback message_handlers() :: [message_handler]

  @optional_callbacks [
    handle_connected: 2,
    init: 2,
    message_handlers: 0
  ]

  alias Clover.{
    Adapter,
    Error,
    MessageHandler,
    User
  }

  alias Clover.Robot.MessageSupervisor
  alias Clover.Util.Logger

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]
  @type message_action :: :say | :reply | :emote
  @type message_handler :: MessageHandler.t()
  @type name :: String.t()

  defmodule Builder do
    @moduledoc false

    defmacro overhear(pattern, function) when is_atom(function) do
      add_message_handler(:overhear, pattern, {__CALLER__.module, function})
    end

    defmacro overhear(pattern, msg, match, data, do: block) do
      handler = {__CALLER__.module, unique_handler_name()}
      add_message_handler_block(:overhear, pattern, handler, msg, match, data, block)
    end

    defmacro respond(pattern, function) when is_atom(function) do
      add_message_handler(:respond, pattern, {__CALLER__.module, function})
    end

    defmacro respond(pattern, msg, match, data, do: block) do
      handler = {__CALLER__.module, unique_handler_name()}
      add_message_handler_block(:respond, pattern, handler, msg, match, data, block)
    end

    @doc false
    defmacro __before_compile__(_env) do
      quote do
        def message_handlers, do: @handlers
      end
    end

    @doc false
    defmacro __after_compile__(env, _bytecode) do
      # Check {mod, fun} handlers and raise error if they are not defined
      for %{respond: respond} <- Module.get_attribute(env.module, :handlers) do
        case respond do
          {mod, fun} when is_atom(mod) and is_atom(fun) ->
            unless Module.defines?(mod, {fun, 3}) do
              raise(Error.exception({:not_exported, {mod, fun, 3}}))
            end

          _ ->
            :ok
        end
      end
    end

    defp add_message_handler(match_mode, pattern, handler) do
      quote do
        @handlers MessageHandler.new(unquote(match_mode), unquote(pattern), unquote(handler))
      end
    end

    defp add_message_handler_block(match_mode, pattern, {mod, fun}, msg, match, data, block) do
      quote do
        @handlers MessageHandler.new(unquote(match_mode), unquote(pattern), unquote({mod, fun}))

        def unquote(fun)(unquote(msg), unquote(match), unquote(data)) do
          unquote(block)
        end
      end
    end

    defp unique_handler_name do
      String.to_atom("__handler_#{System.unique_integer([:positive, :monotonic])}__")
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Robot

      import Clover.Robot.Builder, only: [overhear: 2, overhear: 5, respond: 2, respond: 5]

      Module.register_attribute(__MODULE__, :handlers, accumulate: true)

      @before_compile Clover.Robot.Builder
      @after_compile Clover.Robot.Builder
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

  @spec start_link(any, list) :: GenServer.on_start()
  def start_link(arg, opts \\ [])

  def start_link(arg, opts) do
    GenStateMachine.start_link(__MODULE__, arg, opts)
  end

  @doc false
  def init({name, mod, arg}) do
    Process.flag(:trap_exit, true)

    state = :uninitialized

    data = %{
      mod: mod,
      name: name
    }

    {:ok, data} =
      if function_exported?(mod, :init, 2) do
        mod.init(arg, data)
      else
        {:ok, data}
      end

    {:ok, state, data}
  end

  @spec outgoing(name :: name, {atom, Clover.Message.t()}) :: :ok
  def outgoing(robot_name, {action, message}) when action in [:say, :typing] do
    cast(robot_name, {:outgoing, action, message})
  end

  @spec outgoing_after(name :: name, {atom, Clover.Message.t()}, integer) :: :ok
  def outgoing_after(robot_name, {action, message}, delay) when action in [:say, :typing] do
    cast_after(robot_name, {:outgoing, action, message}, delay)
  end

  def name(robot_name) do
    call(robot_name, :name)
  end

  def incoming(robot_name, message) do
    cast(robot_name, {:incoming, message})
  end

  def connected(robot_name, connection_state) do
    call(robot_name, {:connected, connection_state})
  end

  defp call(robot_name, message) do
    robot_name
    |> Clover.whereis_robot()
    |> GenServer.call(message)
  end

  defp cast(robot_name, message) do
    robot_name
    |> Clover.whereis_robot()
    |> GenServer.cast(message)
  end

  defp cast_after(robot_name, message, delay) do
    cast(robot_name, {:after, message, delay})
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), name}}
  end

  def terminate(reason, _state, _data) do
    log(:info, "terminate", inspect: reason)
  end

  @doc false
  def handle_event(:cast, {:incoming, message}, _state, %{mod: mod, name: name} = data) do
    log(:debug, "message", inspect: message)
    {:ok, _worker} = MessageSupervisor.dispatch(name, mod, data, message)
    :keep_state_and_data
  end

  @doc false
  def handle_event(:cast, {:outgoing, action, message}, _state, %{name: name}) do
    log(:debug, "outgoing", inspect: {action, message})
    Adapter.outgoing(name, :say, message)
    :keep_state_and_data
  end

  @doc false
  # Send event to self after delay. Comes to handle_event/4 with :info tag
  def handle_event(:cast, {:after, message, delay}, _state, _data) do
    Process.send_after(self(), message, delay)
    :keep_state_and_data
  end

  @doc false
  def handle_event({:call, from}, {:connected, connection_state}, _state, %{mod: mod} = data) do
    log(:debug, "connected", inspect: connection_state)

    data =
      case Map.get(connection_state, :me) do
        %User{} = me -> Map.put(data, :me, me)
        _ -> data
      end

    if function_exported?(mod, :handle_connected, 2) do
      case mod.handle_connected(connection_state, data) do
        {:ok, new_data} -> {:next_state, :connected, new_data, [{:reply, from, :ok}]}
        {:error, error} -> {:next_state, :disconnected, data, [{:reply, from, {:error, error}}]}
      end
    else
      {:next_state, :connected, data, [{:reply, from, :ok}]}
    end
  end

  @doc false
  def handle_event({:call, from}, :name, _state, data) do
    %User{name: name} = Map.get(data, :me, %User{})
    {:keep_state_and_data, [{:reply, from, name}]}
  end

  @doc false
  def handle_event(:info, {:outgoing, action, message}, _state, _data) do
    GenServer.cast(self(), {:outgoing, action, message})
    :keep_state_and_data
  end

  @doc false
  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end

  defp log(level, message, opts) do
    Logger.log(level, "robot", message, opts)
  end
end
