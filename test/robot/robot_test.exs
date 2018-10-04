defmodule Hugh.RobotTest do
  use ExUnit.Case, async: true

  alias Hugh.Test.{TestAdapter, TestGlue, TestRobot}
  alias Hugh.{Adapter, Robot}

  setup do
    {:ok, robot} = TestRobot.start_link([], name: :Doug)
    {:ok, adapter} = TestAdapter.start_link([])
    Hugh.Robot.connect(robot, to: adapter)
    Hugh.Adapter.connect(adapter, to: self())

    {:ok, robot: robot, adapter: adapter}
  end

  @tag :focus
  test "adapter sends message", %{adapter: adapter} do
    Adapter.incoming(adapter, "hello")
    assert_receive({:in, "hello"})
  end

  test "robot sends message", %{robot: robot} do
    Robot.send(robot, "goodbye")
    assert_receive({:out, "goodbye"})
  end
end
