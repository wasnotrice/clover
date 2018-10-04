defmodule HughTest do
  use ExUnit.Case
  doctest Hugh

  alias Hugh.Test.{TestAdapter, TestRobot}

  test "starting a robot" do
    {:ok, supervisor} = Hugh.start_robot(TestRobot, adapter: TestAdapter)
    assert Process.alive?(supervisor)
    assert robot = Process.whereis(Hugh.Test.TestRobot)
    assert Process.alive?(robot)
    assert ^robot = Hugh.Robot.Supervisor.whereis_robot(supervisor)
    assert adapter = Hugh.Robot.Supervisor.whereis_adapter(supervisor)
    assert Process.alive?(adapter)
  end

  test "starting a robot with a name" do
    {:ok, supervisor} = Hugh.start_robot(TestRobot, adapter: TestAdapter, name: :carmine)
    assert Process.alive?(supervisor)
    assert robot = Process.whereis(:carmine)
    assert Process.alive?(robot)
  end
end
