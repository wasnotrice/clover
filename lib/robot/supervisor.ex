defmodule Clover.Robot.Supervisor do
  @moduledoc false

  alias Clover.{
    Adapter,
    Robot
  }

  alias Clover.Robot.MessageSupervisor

  def start_link(arg, opts) do
    Supervisor.start_link(__MODULE__, arg, opts)
  end

  def init({name, {robot_mod, robot_arg}, {adapter_mod, adapter_arg}}) do
    children = [
      Robot.child_spec({name, robot_mod, robot_arg}, name: Robot.via_tuple(name)),
      Adapter.child_spec({name, robot_mod, adapter_mod, adapter_arg},
        name: Adapter.via_tuple(name)
      ),
      {DynamicSupervisor, name: MessageSupervisor.via_tuple(name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def child_spec(arg, opts \\ []) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg, opts]}
    }

    Supervisor.child_spec(default, [])
  end
end
