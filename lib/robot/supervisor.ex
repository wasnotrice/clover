defmodule Hugh.Robot.Supervisor do
  alias Hugh.{
    Adapter,
    Robot
  }

  def start_link({name, robot_mod, {adapter, adapter_opts}}, opts) do
    Supervisor.start_link(__MODULE__, {{robot_mod, name}, {adapter, adapter_opts}}, opts)
  end

  def init({{robot_mod, robot_name}, {adapter, adapter_opts}} = arg) do
    IO.inspect(arg, label: "robot.sup.init")

    children = [
      robot_mod.child_spec({robot_name, {adapter, adapter_opts}},
        name: Robot.via_tuple(robot_name)
      ),
      adapter.child_spec({robot_name, adapter_opts},
        name: Adapter.via_tuple(robot_name)
      )
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
