defmodule Clover.Robot.MessageSupervisor do
  @moduledoc false

  alias Clover.Robot.MessageWorker

  @doc """
  Dispatch a raw incoming message to a worker process

  - `message` is the raw message received by the adapter
  - `robot` is the robot module
  - `adapter` is the adapter module
  """
  @spec dispatch(name :: String.t(), message :: any, %{robot: module, adapter: module}) ::
          DynamicSupervisor.on_start_child()
  def dispatch(name, message, context) do
    DynamicSupervisor.start_child(via_tuple(name), {MessageWorker, {message, context}})
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), {name, :messages}}}
  end
end
