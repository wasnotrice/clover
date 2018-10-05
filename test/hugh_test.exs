defmodule HughTest do
  use ExUnit.Case
  doctest Hugh

  alias Hugh.Test.{TestAdapter, TestRobot}

  describe "a supervised robot" do
    setup :start_supervised_robot

    test "starts", %{robot: robot} do
      assert Process.alive?(robot)
      Hugh.Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end

    test "stops", %{robot: robot, supervisor: supervisor} do
      assert Process.alive?(robot)
      assert Process.alive?(supervisor)
      Hugh.stop_supervised_robot(supervisor)
      refute Process.alive?(supervisor)
      refute Process.alive?(robot)
    end
  end

  def start_supervised_robot(_) do
    {:ok, robot, supervisor} = Hugh.start_supervised_robot(TestRobot, {TestAdapter, sink: self()})

    on_exit(fn ->
      Hugh.stop_supervised_robot(supervisor)
    end)

    {:ok, robot: robot, supervisor: supervisor}
  end
end
