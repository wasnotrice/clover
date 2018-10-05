defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  alias Hugh.Adapter

  @callback handle_message({tag :: atom, message :: map}, data :: data) :: {:noreply, data}

  @optional_callbacks [
    handle_message: 2
  ]

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]

  require Logger

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

  def get_adapter(robot) do
    GenStateMachine.call(robot, :get_adapter)
  end

  def handle_in(robot, message) do
    GenStateMachine.cast(robot, {:incoming, message})
  end

  def connect(robot, to: adapter) do
    GenStateMachine.call(robot, {:connect_adapter, adapter})
  end

  def handle_event(:cast, {:incoming, message}, _state, %{mod: mod, adapter: adapter} = data) do
    if function_exported?(mod, :handle_message, 2) do
      _ =
        Logger.debug(
          "Adapter calling #{mod}.handle_message(#{inspect(message)}, #{inspect(data)})"
        )

      case mod.handle_message(message, data) do
        {:reply, {:send, message}, _data} ->
          Adapter.send(adapter, message)
          :keep_state_and_data

        bad_return ->
          _ = Logger.warn("bad return from #{mod}.handle_message/2: #{inspect(bad_return)}")
      end
    else
      _ = Logger.warn(Hugh.format_error({:not_exported, {mod, "handle_message/2"}}))
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
    {:next_state, :connected, new_data, [{:reply, from, :ok}]}
  end

  def handle_event({:call, from}, :get_adapter, _state, %{adapter: adapter}) do
    {:keep_state_and_data, [{:reply, from, adapter}]}
  end

  def handle_event(_type, _event, _state, _data) do
    :keep_state_and_data
  end
end
