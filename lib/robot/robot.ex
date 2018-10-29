defmodule Clover.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @callback handle_connected(connection_state :: map, data :: data()) ::
              {:ok, data()} | {:error, Clover.Error}
  @callback init(arg :: any, data :: any) :: GenServer.on_start()
  @callback scripts() :: [script]

  @optional_callbacks [
    handle_connected: 2,
    init: 2,
    scripts: 0
  ]

  alias Clover.{
    Adapter,
    Error,
    Message,
    Script,
    User
  }

  alias Clover.Robot.MessageSupervisor
  alias Clover.Util.Logger

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]
  @type message_action :: :say | :reply | :emote
  @type script :: Script.t()
  @type name :: String.t()

  defmodule Builder do
    @moduledoc false

    defmacro script(module, options \\ []) do
      add_script_module(module, options)
    end

    defmacro overhear(pattern, function) when is_atom(function) do
      add_script(:overhear, pattern, {__CALLER__.module, function})
    end

    defmacro overhear(pattern, msg, match, data, do: block) do
      script = {__CALLER__.module, unique_script_name()}
      add_script_block(:overhear, pattern, script, msg, match, data, block)
    end

    defmacro respond(pattern, function) when is_atom(function) do
      add_script(:respond, pattern, {__CALLER__.module, function})
    end

    defmacro respond(pattern, msg, match, data, do: block) do
      script = {__CALLER__.module, unique_script_name()}
      add_script_block(:respond, pattern, script, msg, match, data, block)
    end

    @doc false
    defmacro __before_compile__(_env) do
      quote do
        def scripts, do: @scripts
      end
    end

    @doc false
    defmacro __after_compile__(env, _bytecode) do
      # Check {mod, fun} scripts and raise error if they are not defined
      for %{respond: respond} <- Module.get_attribute(env.module, :scripts) do
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

    defp add_script(match_mode, pattern, script) do
      quote do
        @scripts Script.new(unquote(match_mode), unquote(pattern), unquote(script))
      end
    end

    defp add_script_block(match_mode, pattern, {mod, fun}, msg, match, data, block) do
      quote do
        @scripts Script.new(unquote(match_mode), unquote(pattern), unquote({mod, fun}))

        def unquote(fun)(unquote(msg), unquote(match), unquote(data)) do
          unquote(block)
        end
      end
    end

    def add_script_module(mod, _options) do
      quote do
        @scripts Script.new(:overhear, unquote(Macro.escape(~r/^.*$/)), unquote(mod))
      end
    end

    defp unique_script_name do
      String.to_atom("__script_#{System.unique_integer([:positive, :monotonic])}__")
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Robot

      import Clover.Robot.Builder,
        only: [script: 1, script: 2, overhear: 2, overhear: 5, respond: 2, respond: 5]

      import Clover.Message, only: [say: 2, say: 3, typing: 1, typing: 2]

      Module.register_attribute(__MODULE__, :scripts, accumulate: true)

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
      if function_exported?(mod, :init, 2),
        do: mod.init(arg, data),
        else: {:ok, data}

    {:ok, state, data}
  end

  @spec outgoing(name :: name, Message.t()) :: :ok
  def outgoing(robot_name, %Message{action: action, delay: delay} = message)
      when is_integer(delay) and action in [:say, :typing] do
    log(:debug, "outgoing delayed", inspect: message)
    cast_after(robot_name, {:outgoing, message}, delay)
  end

  def outgoing(robot_name, %Message{action: action} = message) when action in [:say, :typing] do
    log(:debug, "outgoing immediate", inspect: message)

    cast(robot_name, {:outgoing, message})
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
    cast(robot_name, {:delay, message, delay})
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
  def handle_event(:cast, {:outgoing, message}, _state, %{name: name}) do
    log(:debug, "outgoing", inspect: message)
    Adapter.outgoing(name, message)
    :keep_state_and_data
  end

  @doc false
  # Send event to self after delay. Comes to handle_event/4 with :info tag
  def handle_event(:cast, {:delay, message, delay}, _state, _data) do
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
  def handle_event(:info, {:outgoing, message}, _state, _data) do
    GenServer.cast(self(), {:outgoing, message})
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
