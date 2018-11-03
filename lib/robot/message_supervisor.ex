defmodule Clover.Robot.MessageSupervisor do
  @moduledoc false

  alias Clover.Robot.MessageWorker

  def dispatch(name, robot_mod, robot_data, message) do
    DynamicSupervisor.start_child(
      via_tuple(name),
      {MessageWorker, {name, robot_mod, robot_data, message}}
    )
  end

  @doc """
  Dispatch a raw incoming message to a worker process

  - `message` is the raw message received by the adapter
  - `context` is arbitrary adapter-specific context
  """
  @spec dispatch(name :: String.t(), message :: any, %{
          robot_mod: module,
          adapter_mod: module,
          adapter_context: map
        }) :: DynamicSupervisor.on_start_child()
  def dispatch(name, message, context) do
    DynamicSupervisor.start_child(
      via_tuple(name),
      {MessageWorker, {name, message, context}}
    )
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), {name, :messages}}}
  end
end
