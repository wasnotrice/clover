defmodule Clover.RobotTest do
  use ExUnit.Case, async: true

  alias Clover.Test.{TestAdapter, TestRobot}
  alias Clover.{Adapter, Robot, User}
  alias Clover.Robot.Supervisor, as: RobotSupervisor

  setup do
    name = "doug"
    child_spec = RobotSupervisor.child_spec({name, TestRobot, {TestAdapter, sink: self()}}, [])
    _pid = start_supervised!(child_spec)
    {:ok, name: name}
  end

  test "robot responds to message", %{name: name} do
    Adapter.incoming(name, "ping", %{})
    assert_receive({:out, "pong"})
  end

  test "robot sends message", %{name: name} do
    Robot.send(name, "goodbye")
    assert_receive({:out, "goodbye"})
  end

  test "robot receives name", %{name: robot_name} do
    robot_user = %User{id: "alice", name: "alice"}
    Adapter.connected(robot_name, %{me: robot_user})
    assert Robot.name(robot_name) == "alice"
  end
end
