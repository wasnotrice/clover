defmodule Hugh.RobotTest do
  use ExUnit.Case, async: true

  alias Hugh.Test.{TestAdapter, TestRobot}
  alias Hugh.{Adapter, Robot}

  setup do
    {:ok, _pid} = Hugh.start_robot(TestRobot, name: :Doug, adapter: TestAdapter)
    {:ok, []}
  end

  test "receives message" do
    Adapter.send("hello")
  end
end
