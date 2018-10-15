defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @callback message_handlers() :: [message_handler]
  @callback handle_connected(connection_state :: map, data :: data()) ::
              {:ok, data()} | {:error, Hugh.Error}

  @optional_callbacks [
    message_handlers: 0
  ]

  alias Hugh.{
    Adapter,
    Message,
    MessageHandler,
    User
  }

  alias Hugh.Util.Logger

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]
  @type message_action :: :send | :reply | :emote
  @type message_handler :: MessageHandler.t()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Hugh.Robot

      if Code.ensure_loaded?(Supervisor) and function_exported?(Supervisor, :init, 2) do
        @doc false
        def child_spec(arg, opts \\ []) do
          default = %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [arg, opts]}
          }

          Supervisor.child_spec(default, unquote(Macro.escape(opts)))
        end

        defoverridable child_spec: 2
      end
    end
  end

  @spec start_link(atom(), {String.t(), atom() | {atom(), any()}}) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(mod, name) do
    start_link(mod, name, [])
  end

  def start_link(mod, name, opts) do
    GenStateMachine.start_link(__MODULE__, {mod, name}, opts)
  end

  def init({mod, name} = arg) do
    Process.flag(:trap_exit, true)

    state = :uninitialized

    data = %{
      mod: mod,
      name: name
    }

    {:ok, data} = mod.init(arg, data)

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
    |> Hugh.whereis_robot()
    |> GenServer.call(message)
  end

  defp cast(robot_name, message) do
    robot_name
    |> Hugh.whereis_robot()
    |> GenServer.cast(message)
  end

  def via_tuple(name) do
    {:via, Registry, {Hugh.registry(), name}}
  end

  def terminate(reason, _state, _data) do
    log(:error, "terminate", inspect: reason)
  end

  def handle_event(:cast, {:incoming, message}, _state, %{mod: mod, name: name} = data) do
    log(:debug, "message", inspect: message)

    handlers =
      if function_exported?(mod, :message_handlers, 0),
        do: mod.message_handlers(),
        else: []

    case handle_message(message, data, handlers) do
      {:send, message, new_data} ->
        Adapter.send(name, message)
        {:keep_state, new_data}

      {:noreply, new_data} ->
        {:keep_state, new_data}

      bad_return ->
        _ = log(:warn, "bad return from #{mod}.handle_message/2: #{inspect(bad_return)}")
        :keep_state_and_data
    end
  end

  def handle_event(:cast, {:send, text}, _state, %{name: name} = data)
      when is_binary(text) do
    Adapter.send(name, text)
    :keep_state_and_data
  end

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

  def handle_event({:call, from}, :name, _state, data) do
    %User{name: name} = Map.get(data, :me, %User{})
    {:keep_state_and_data, [{:reply, from, name}]}
  end

  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end

  defp handle_message(_message, data, []), do: {:noreply, data}

  defp handle_message(message, data, [handler | tail]) do
    case MessageHandler.handle(handler, message, data) do
      {mode, message, data} ->
        {mode, message, data}

      _ ->
        log(:debug, "no handler match", inspect: handler)
        handle_message(message, data, tail)
    end
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, "robot", message, opts)
  end
end
