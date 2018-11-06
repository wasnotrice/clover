defmodule Clover.Robot.MessageSupervisor do
  @moduledoc false

  alias Clover.Robot.MessageWorker

  @type worker_context :: %{
          adapter: module,
          connection: map,
          me: Clover.User.t(),
          name: String.t(),
          robot: module
        }

  @doc """
  Dispatch a raw incoming message to a worker process

  - `name` is the name of the robot
  - `message` is the raw message received by the adapter
  - `context` is the context for processing the message, based on robot state
  """
  @spec dispatch(name :: String.t(), message :: any, context :: worker_context) ::
          DynamicSupervisor.on_start_child()
  def dispatch(name, message, context) do
    DynamicSupervisor.start_child(via_tuple(name), {MessageWorker, {message, context}})
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), {name, :messages}}}
  end
end
