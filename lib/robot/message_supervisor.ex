defmodule Clover.Robot.MessageSupervisor do
  @moduledoc false

  alias Clover.Robot.MessageWorker

  def dispatch(name, robot_mod, robot_data, message) do
    DynamicSupervisor.start_child(
      via_tuple(name),
      {MessageWorker, {name, robot_mod, robot_data, message}}
    )
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), {name, :messages}}}
  end
end
