defmodule HughTest do
  use ExUnit.Case
  doctest Hugh

  alias Hugh.Test.{TestAdapter, TestRobot}

  describe "starting a robot" do
    setup :start_supervised_robot

    test "starting a robot", %{robot: robot} do
      assert Process.alive?(robot)
      Hugh.Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end
  end

  def start_supervised_robot(_) do
    {:ok, robot, supervisor} =
      Hugh.start_supervised_robot(TestRobot, adapter: TestAdapter, sink: self())

    on_exit(fn ->
      Hugh.stop_supervised_robot(supervisor)
    end)

    {:ok, robot: robot}
  end
end
