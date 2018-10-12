defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @callback message_handlers() :: [function]
  @callback handle_connected(connection_state :: map, data :: data()) ::
              {:ok, data()} | {:error, Hugh.Error}

  @optional_callbacks [
    message_handlers: 0
  ]

  alias Hugh.{
    Adapter,
    Message
  }

  alias Hugh.Util.Logger

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]
  @type message_action :: :send | :reply | :emote

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

  def start_link(mod, adapter) do
    start_link(mod, adapter, [])
  end

  def start_link(mod, adapter, opts) when is_atom(adapter) do
    start_link(mod, {adapter, []}, opts)
  end

  def start_link(mod, {adapter, adapter_opts}, opts) do
    name = Keyword.get(opts, :name)
    GenStateMachine.start_link(__MODULE__, {mod, {adapter, adapter_opts}, name}, opts)
  end

  def init({mod, {adapter, adapter_opts}, name} = arg) do
    opts = Keyword.put(adapter_opts, :robot_name, name)
    {:ok, adapter} = Hugh.Adapter.Supervisor.start_adapter(adapter, adapter_opts, self(), opts)

    state = :uninitialized
    {:ok, data} = mod.init(arg)

    data =
      data
      |> Map.put(:adapter, adapter)
      |> Map.put(:mod, mod)

    {:ok, state, data}
  end

  @spec send(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) :: :ok
  def send(robot, message) do
    GenStateMachine.cast(robot, {:send, message})
  end

  def name(robot) do
    GenStateMachine.call(robot, :name)
  end

  def get_adapter(robot) do
    GenStateMachine.call(robot, :get_adapter)
  end

  def handle_in(robot, message) do
    GenStateMachine.cast(robot, {:incoming, message})
  end

  def connect(robot, to: adapter) do
    GenStateMachine.call(robot, {:connect_adapter, adapter})
  end

  def connected(robot, connection_state) do
    GenStateMachine.call(robot, {:connected, connection_state})
  end

  def handle_event(:cast, {:incoming, message}, _state, %{mod: mod, adapter: adapter} = data) do
    handlers =
      if function_exported?(mod, :message_handlers, 0),
        do: mod.message_handlers(),
        else: []

    case handle_message(message, data, handlers) do
      {:send, message, new_data} ->
        Adapter.send(adapter, message)
        {:keep_state, new_data}

      {:noreply, new_data} ->
        {:keep_state, new_data}

      bad_return ->
        _ = log(:warn, "bad return from #{mod}.handle_message/2: #{inspect(bad_return)}")
        :keep_state_and_data
    end
  end

  def handle_event(:cast, {:send, message}, _state, %{adapter: adapter}) do
    Adapter.send(adapter, message)
    :keep_state_and_data
  end

  def handle_event({:call, from}, {:connect_adapter, adapter}, _state, data) do
    :ok = Adapter.connect(adapter, to: self())
    new_data = Map.put(data, :adapter, adapter)
    {:next_state, :connecting, new_data, [{:reply, from, :ok}]}
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

  def handle_event({:call, from}, :get_adapter, _state, %{adapter: adapter}) do
    {:keep_state_and_data, [{:reply, from, adapter}]}
  end

  def handle_event({:call, from}, :name, _state, data) do
    %User{name: name} = Map.get(data, :me, %User{})
    {:keep_state_and_data, [{:reply, from, name}]}
  end

  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end

  defp handle_message(_message, data, []), do: {:noreply, data}

  defp handle_message(message, data, [%{match: match, respond: respond} | tail]) do
    message.text
    |> trim_leading_mention("me", message.mentions)
    |> String.match?(match)
    |> case do
      true ->
        respond.(message, data)

      false ->
        log(:debug, "no handler match", inspect: match)
        handle_message(message, data, tail)
    end
  end

  defp trim_leading_mention(text, me, mentions) do
    mentions
    |> Enum.find(fn {id, {start, _}} -> id == me && start == 0 end)
    |> case do
      nil -> text
      {_, {start, length}} -> String.slice(text, start..length)
    end
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, message, Keyword.put(opts, :label, "robot"))
  end
end
