defmodule CloverTest do
  use ExUnit.Case, async: false
  doctest Clover

  alias Clover.Robot
  alias Clover.Test.{TestAdapter, TestRobot}

  describe "a supervised robot" do
    setup :start_supervised_robot

    test "starts", %{robot: robot} do
      Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end

    test "restarts", %{robot: robot} do
      assert pid = Clover.whereis_robot(robot)
      assert Process.alive?(pid)

      # Kill robot
      spawn(fn -> Process.exit(pid, :kill) end)
      assert_down(pid)

      # Wait for robot to be restarted
      Process.sleep(10)

      assert restarted_pid = Clover.whereis_robot(robot)
      assert restarted_pid != pid
    end

    test "stops", %{robot: robot} do
      pid = Clover.whereis_robot(robot)
      assert Process.alive?(pid)
      Clover.stop_supervised_robot(robot)
      assert_down(pid)

      # Wait for robot to be restarted
      Process.sleep(10)

      refute Clover.whereis_robot(robot)
    end
  end

  describe "an unsupervised robot" do
    setup :start_unsupervised_robot

    test "starts", %{robot: robot} do
      Robot.send(robot, "hello")
      assert_receive {:out, "hello"}
    end

    test "is not started under supervisor", %{robot: robot} do
      assert pid = Clover.whereis_robot(robot)
      assert Process.alive?(pid)
      assert [] = Supervisor.which_children(Clover.Robots)
    end

    test "stops", %{robot: robot, robot_sup: robot_sup} do
      pid = Clover.whereis_robot(robot)
      assert Process.alive?(pid)
      Supervisor.stop(robot_sup)
      assert_down(pid)

      # Wait for robot to [not] be restarted
      Process.sleep(10)

      refute Clover.whereis_robot(robot)
    end
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end

  def start_supervised_robot(_) do
    robot = "hugh"
    {:ok, pid} = Clover.start_supervised_robot(robot, TestRobot, {TestAdapter, sink: self()})

    on_exit(fn ->
      if Process.alive?(pid) do
        Clover.stop_supervised_robot(robot)
        assert_down(pid)
      end
    end)

    {:ok, robot: robot}
  end

  def start_unsupervised_robot(_) do
    robot = "doug"
    test_process = self()

    # Spawn a process to start the robot process, so the test process isn't linked
    # to the robot process. This makes it possible to test stopping the robot without
    # taking down the test process.
    robot_starter =
      spawn(fn ->
        {:ok, pid} = Clover.start_robot(robot, TestRobot, {TestAdapter, sink: test_process})
        send(test_process, {:robot_supervisor_pid, pid})
        Process.flag(:trap_exit, true)

        receive do
          {:EXIT, ^pid, _reason} -> :ok
        end
      end)

    # Get the robot pid from the starter process
    pid =
      receive do
        {:robot_supervisor_pid, pid} -> pid
      end

    on_exit(fn ->
      if Process.alive?(pid) do
        Supervisor.stop(pid)
        assert_down(pid)
      end

      # Always clean up the starter process
      Process.exit(robot_starter, :kill)
    end)

    {:ok, robot: robot, robot_sup: pid}
  end
end
