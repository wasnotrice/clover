defmodule Clover.Adapter do
  @moduledoc """
  A Behaviour for `Clover` chat platform adapters.
  """
  use GenServer

  alias Clover.{
    Message,
    Robot
  }

  @type state :: map

  @callback handle_in({tag :: atom, any()}, state :: state, context :: map) ::
              {:message, Message.t(), state}
  @callback handle_out({tag :: atom, message :: Message.t()}, state :: state) ::
              {:sent, Message.t(), state}
  @callback init(arg :: any, state :: state()) :: Genserver.on_start()

  @optional_callbacks [
    handle_in: 3,
    handle_out: 2,
    init: 2
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

    Supervisor.child_spec(default, %{})
  end

  def start_link(arg, opts) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  @doc false
  def init({robot, mod, arg}) do
    state = %{
      mod: mod,
      robot: robot
    }

    if function_exported?(mod, :init, 2) do
      mod.init(arg, state)
    else
      {:ok, state}
    end
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
  def handle_call({:connected, connection_state}, _from, %{robot: robot} = state) do
    log(:debug, "connected", inspect: connection_state)
    Robot.connected(robot, connection_state)
    {:reply, :ok, state}
  end

  @doc false
  def handle_cast({:incoming, message, context}, %{mod: mod, robot: robot} = state) do
    if function_exported?(mod, :handle_in, 3) do
      case mod.handle_in({:message, message}, state, context) do
        {:message, message, state} ->
          Robot.handle_in(robot, message)
          {:noreply, state}

        _ ->
          log(:error, Clover.format_error({:unhandled_message, message}))
      end
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
    alias Clover.Util.Logger
    Logger.log(level, "adapter", message, opts)
  end
end
