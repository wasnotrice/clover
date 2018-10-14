defmodule HughTest do
  use ExUnit.Case, async: false
  doctest Hugh

  alias Hugh.Test.{TestAdapter, TestRobot}

  describe "a supervised robot" do
    setup :start_supervised_robot

    test "starts", %{robot: robot, pid: pid} do
      Hugh.Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end

    test "restarts", %{robot: robot} do
      # assert [child] = Supervisor.which_children(Hugh.Robots)
      # assert {_, ^robot, :worker, [Hugh.Test.TestRobot]} = child
      assert pid = Hugh.whereis_robot(robot)
      assert Process.alive?(pid)

      # Kill robot
      spawn(fn -> Process.exit(pid, :kill) end)
      assert_down(pid)

      # Wait for robot to be restarted
      Process.sleep(10)

      assert restarted_pid = Hugh.whereis_robot(robot)
      refute restarted_pid == pid
    end

    test "stops", %{robot: robot} do
      pid = Hugh.whereis_robot(robot)
      assert Process.alive?(pid)
      Hugh.stop_supervised_robot(robot)
      assert_down(pid)
    end
  end

  describe "an unsupervised robot" do
    setup :start_unsupervised_robot

    test "starts", %{robot: robot} do
      Hugh.Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end

    test "is not started under supervisor", %{robot: robot} do
      assert pid = Hugh.whereis_robot(robot)
      assert Process.alive?(pid)
      assert [] = Supervisor.which_children(Hugh.Robots)
    end

    test "stops", %{robot: robot} do
      pid = Hugh.whereis_robot(robot)
      assert Process.alive?(pid)
      Hugh.stop_robot(robot)
      assert_down(pid)

      # Wait for robot to be restarted
      Process.sleep(10)

      refute Hugh.whereis_robot(robot)
    end
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end

  def start_supervised_robot(_) do
    robot = "hugh"
    {:ok, pid} = Hugh.start_supervised_robot(robot, TestRobot, {TestAdapter, sink: self()})
    IO.inspect(pid, label: "start")

    on_exit(fn ->
      Hugh.stop_supervised_robot(robot)
    end)

    {:ok, robot: robot, pid: pid}
  end

  def start_unsupervised_robot(_) do
    robot = "doug"
    {:ok, pid} = Hugh.start_robot(robot, TestRobot, {TestAdapter, sink: self()})

    on_exit(fn ->
      if Process.alive?(pid) do
        Hugh.stop_robot(robot)
        assert_down(pid)
      end
    end)

    {:ok, robot: robot, pid: pid}
  end
end
