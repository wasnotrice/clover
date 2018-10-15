defmodule Clover.Adapter do
  use GenServer

  alias Clover.{
    Message,
    Robot
  }

  @type state :: map

  @callback handle_in({tag :: atom, message :: Message.t()}, state :: state, context :: map) ::
              {:message, Message.t(), state}
  @callback handle_out({tag :: atom, message :: Message.t()}, state :: state) ::
              {:sent, Message.t(), state}

  @optional_callbacks [
    handle_in: 3,
    handle_out: 2
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Adapter

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

  @doc false
  def init({mod, robot, arg}) do
    state = %{
      mod: mod,
      robot: robot
    }

    {:ok, state} = mod.init(arg, state)

    {:ok, state}
  end

  def connected(robot_name, state) do
    call(robot_name, {:connected, state})
  end

  def send(robot_name, message) do
    cast(robot_name, {:send, message})
  end

  def incoming(robot_name, message, context) do
    cast(robot_name, {:incoming, message, context})
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
  def handle_call({:connect_robot, robot}, _from, state) do
    new_state = Map.put(state, :robot, robot)
    {:reply, :ok, new_state}
  end

  @doc false
  def handle_call({:connected, connection_state}, _from, %{robot: robot} = state) do
    log(:debug, "connected", inspect: connection_state)
    Robot.connected(robot, connection_state)
    {:reply, :ok, state}
  end

  @doc false
  def handle_cast({:incoming, message, context}, %{mod: mod, robot: robot} = state) do
    if function_exported?(mod, :handle_in, 3) do
      {:ok, message, state} = mod.handle_in({:message, message}, state, context)
      Robot.handle_in(robot, message)
      {:noreply, state}
    else
      log(:error, Clover.format_error({:not_exported, {mod, "handle_in/2"}}))
      {:noreply, state}
    end
  end

  @doc false
  def handle_cast({:send, message}, %{mod: mod} = state) do
    if function_exported?(mod, :handle_out, 2) do
      log(:debug, "Adapter calling #{mod}.handle_out(#{inspect(message)}, #{inspect(state)})")

      mod.handle_out({:send, message}, state)
      {:noreply, state}
    else
      log(:warn, Clover.format_error({:not_exported, {mod, "handle_out/2"}}))
      {:noreply, state}
    end
  end

  defp log(level, message, opts \\ []) do
    Clover.Util.Logger.log(level, "adapter", message, opts)
  end
end
