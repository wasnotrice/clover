defmodule Hugh.Adapter do
  use GenServer

  alias Hugh.{
    Message,
    Robot
  }

  @type state :: map

  @callback handle_in({tag :: atom, message :: Message.t()}, state :: state, context :: map) ::
              {:message, Message.t(), state}
  @callback handle_out({tag :: atom, message :: Message.t()}, state :: state) ::
              {:sent, Message.t(), state}

  @doc """
  A suffix for this process's name in the local registry.

  If your robot is named `:Mike`, then your adapter will be `:Mike.Adapter`.
  """
  @callback process_suffix :: String.t()

  @optional_callbacks [
    handle_in: 3,
    handle_out: 2,
    process_suffix: 0
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Hugh.Adapter

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

  def start_link(mod, {robot, arg}, opts) do
    GenServer.start_link(__MODULE__, {mod, robot, arg}, opts)
  end

  def init({mod, robot, arg}) do
    state = %{
      mod: mod,
      robot: robot
    }

    {:ok, state} = mod.init(arg, state)
    {:ok, state}
  end

  def connect(adapter, to: robot) do
    GenServer.call(adapter, {:connect_robot, robot})
  end

  def connected(adapter, state) do
    GenServer.call(adapter, {:connected, state})
  end

  def send(adapter, message) do
    GenServer.cast(adapter, {:send, message})
  end

  def incoming(adapter, message, context) do
    GenServer.cast(adapter, {:incoming, message, context})
  end

  def process_suffix(adapter) do
    if function_exported?(adapter, :process_suffix, 0) do
      adapter.process_suffix
    else
      "Adapter"
    end
  end

  def handle_call({:connect_robot, robot}, _from, state) do
    new_state = Map.put(state, :robot, robot)
    {:reply, :ok, new_state}
  end

  def handle_call({:connected, connection_state}, _from, %{robot: robot} = state) do
    log(:debug, "connected", inspect: connection_state)
    Robot.connected(robot, connection_state)
    {:reply, :ok, state}
  end

  def handle_cast({:incoming, message, context}, %{mod: mod, robot: robot} = state) do
    if function_exported?(mod, :handle_in, 3) do
      {:ok, message, state} = mod.handle_in({:message, message}, state, context)
      Robot.handle_in(robot, message)
      {:noreply, state}
    else
      _ = log(:error, Hugh.format_error({:not_exported, {mod, "handle_in/2"}}))
      {:noreply, state}
    end
  end

  def handle_cast({:send, message}, %{mod: mod} = state) do
    if function_exported?(mod, :handle_out, 2) do
      log(:debug, "Adapter calling #{mod}.handle_out(#{inspect(message)}, #{inspect(state)})")

      mod.handle_out({:send, message}, state)
      {:noreply, state}
    else
      log(:warn, Hugh.format_error({:not_exported, {mod, "handle_out/2"}}))
      {:noreply, state}
    end
  end

  def log(level, message, opts \\ []) do
    Hugh.Util.Logger.log(level, "adapter", message, opts)
  end
end
