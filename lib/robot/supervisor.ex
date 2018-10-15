defmodule Hugh.Robot.Supervisor do
  alias Hugh.{
    Adapter,
    Robot
  }

  def start_link({name, robot_mod, {adapter, adapter_opts}}, opts) do
    Supervisor.start_link(__MODULE__, {name, robot_mod, {adapter, adapter_opts}}, opts)
  end

  def init({name, robot_mod, {adapter, adapter_opts}}) do
    children = [
      robot_mod.child_spec(name, name: Robot.via_tuple(name)),
      adapter.child_spec({name, adapter_opts}, name: Adapter.via_tuple(name))
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def child_spec(arg, opts) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg, opts]}
    }

    Supervisor.child_spec(default, opts)
  end
end
