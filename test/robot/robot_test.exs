defmodule Hugh.RobotTest do
  use ExUnit.Case, async: true

  alias Hugh.Test.{TestAdapter, TestGlue, TestRobot}
  alias Hugh.{Adapter, Robot}

  setup do
    opts = [name: :Doug, adapter: TestAdapter, glue: {TestGlue, self()}]
    {:ok, robot} = TestRobot.start_link(opts)
    {:ok, adapter} = TestAdapter.start_link(opts)

    on_exit(fn ->
      Process.exit(robot, :kill)
      Process.exit(adapter, :kill)
    end)

    {:ok, robot: robot, adapter: adapter}
  end

  @tag :focus
  test "adapter sends message", %{adapter: adapter} do
    TestAdapter.send(adapter, "hello")
    assert_receive({:message, "hello"})
  end

  test "robot sends message", %{robot: robot} do
    Robot.send(robot, "goodbye")
    assert_receive({:message, "goodbye"})
  end
end
