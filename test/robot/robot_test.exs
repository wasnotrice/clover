defmodule Hugh.RobotTest do
  use ExUnit.Case, async: true

  alias Hugh.Test.{TestAdapter, TestRobot}
  alias Hugh.{Adapter, Robot}

  setup do
    {:ok, pid} = Hugh.start_robot(TestRobot, name: :Doug, adapter: TestAdapter)
    robot = Hugh.Robot.Supervisor.find_robot(pid)
    adapter = Hugh.Robot.Supervisor.find_adapter(pid)
    TestAdapter.add_receiver(adapter, self())

    on_exit(fn ->
      Process.exit(pid, :kill)
    end)

    {:ok, robot: robot, adapter: adapter}
  end

  # test "adapter sends message", %{adapter: adapter} do
  #   TestAdapter.send(adapter, "hello")
  #   assert_receive({:message, "hello"})
  # end

  test "robot sends message", %{robot: robot} do
    Robot.send(robot, "goodbye")
    assert_receive({:send, "goodbye"})
  end
end
