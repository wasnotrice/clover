defmodule Hugh do
  @moduledoc """
  Documentation for Hugh.
  """

  use Application

  def start(_type, _args) do
    Hugh.Supervisor.start_link(name: Hugh.App)
  end

  def start_supervised_robot(mod, opts \\ []) do
    adapter = Keyword.fetch!(opts, :adapter)

    start_opts = Keyword.take(opts, [:name, :timeout, :debug, :spawn_opt])

    {:ok, sup} = Supervisor.start_link(Hugh.Robot.Supervisor, [], [])
    {:ok, robot} = Supervisor.start_child(sup, mod.child_spec(opts, start_opts))
    {:ok, adapter} = Supervisor.start_child(sup, adapter.child_spec(opts, start_opts))

    :ok = Hugh.Robot.connect(robot, to: adapter)

    {:ok, robot, sup}
  end

  def stop_supervised_robot(sup, _opts \\ []) do
    Process.exit(sup, :normal)
  end

  def format_error(reason) do
    reason
  end
end
