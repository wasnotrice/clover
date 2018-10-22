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
  @type message_action :: :send | :reply | :emote
  @type message_handler :: MessageHandler.t()

  defmodule Builder do
    @moduledoc false

    defmacro overhear(pattern, handler) do
      handler =
        case handler do
          fun when is_atom(fun) -> {__CALLER__.module, fun}
          fun when is_function(fun) -> fun
        end

      quote do
        @handlers MessageHandler.new(:overhear, unquote(pattern), unquote(handler))
      end
    end

    defmacro respond(pattern, handler) do
      handler =
        case handler do
          fun when is_atom(fun) -> {__CALLER__.module, fun}
          fun when is_function(fun) -> fun
        end

      quote do
        @handlers MessageHandler.new(:respond, unquote(pattern), unquote(handler))
      end
    end

    @doc false
    defmacro __before_compile__(_env) do
      quote do
        def message_handlers do
          @handlers
        end
      end
    end

    @doc false
    defmacro __after_compile__(env, _bytecode) do
      # Check {mod, fun} handlers and raise error if they are not defined
      for %{respond: respond} <- Module.get_attribute(env.module, :handlers) do
        case respond do
          {mod, fun} when is_atom(mod) and is_atom(fun) ->
            unless Module.defines?(mod, {fun, 3}) do
              raise Error.exception({:not_exported, {mod, fun, 3}})
            end

          _ ->
            :ok
        end
      end
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Robot

      import Clover.Robot.Builder, only: [overhear: 2, respond: 2]

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

  @spec send(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) :: :ok
  def send(robot_name, message) do
    cast(robot_name, {:send, message})
  end

  def name(robot_name) do
    call(robot_name, :name)
  end

  def handle_in(robot_name, message) do
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
  def handle_event(:cast, {:send, text}, _state, %{name: name})
      when is_binary(text) do
    Adapter.send(name, text)
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
  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end

  defp log(level, message, opts) do
    Logger.log(level, "robot", message, opts)
  end
end
