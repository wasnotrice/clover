defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  alias Hugh.Adapter

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]

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

  def start_link(mod, arg, opts) do
    GenStateMachine.start_link(__MODULE__, {mod, arg}, opts)
  end

  def init({mod, arg}) do
    state = Keyword.get(arg, :state, :uninitialized)
    {:ok, data} = mod.init(arg)
    {:ok, state, data}
  end

  def send(robot, message) do
    GenStateMachine.cast(robot, {:send, message})
  end

  def handle_in(robot, message) do
    GenStateMachine.cast(robot, {:incoming, message})
  end

  def connect(robot, to: adapter) do
    GenStateMachine.call(robot, {:connect_adapter, adapter})
  end

  def handle_event(:cast, {:incoming, message}, _state, _data) do
    IO.inspect(message, label: "incoming")
    :keep_state_and_data
  end

  def handle_event(:cast, {:send, message}, _state, %{adapter: adapter}) do
    Adapter.send(adapter, message)
    :keep_state_and_data
  end

  def handle_event({:call, from}, {:connect_adapter, adapter}, _state, data) do
    IO.puts("connecting to adapter #{inspect(adapter)}")
    :ok = Adapter.connect(adapter, to: self())
    new_data = Map.put(data, :adapter, adapter)
    {:next_state, :connected, new_data, [{:reply, from, :ok}]}
  end

  def handle_event(type, event, _state, _data) do
    IO.inspect(%{type: type, event: event}, label: "robot unhandled")
    :keep_state_and_data
  end
end
