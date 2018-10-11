defmodule Hugh.RobotTest do
  use ExUnit.Case, async: true

  alias Hugh.Test.{TestAdapter, TestRobot}
  alias Hugh.{Adapter, Robot}

  setup do
    robot = start_supervised!(TestRobot.child_spec({TestAdapter, sink: self()}, name: Doug))

    adapter = Robot.get_adapter(robot)
    {:ok, robot: robot, adapter: adapter}
  end

  test "robot responds to message", %{adapter: adapter} do
    Adapter.incoming(adapter, "ping", %{})
    assert_receive({:out, "pong"})
  end

  test "robot sends message", %{robot: robot} do
    Robot.send(robot, "goodbye")
    assert_receive({:out, "goodbye"})
  end

  test "robot receives name", %{robot: robot, adapter: adapter} do
    Adapter.connected(adapter, %{robot_name: "doug"})
    assert Robot.name(robot) == "doug"
  end
end
