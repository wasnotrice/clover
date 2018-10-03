defmodule HughTest do
  use ExUnit.Case
  doctest Hugh

  alias Hugh.Robot.TestRobot

  test "starting a robot" do
    {:ok, supervisor} = Hugh.start_robot(TestRobot)
    assert Process.alive?(supervisor)
    assert robot = Process.whereis(Hugh.Robot.TestRobot)
    assert Process.alive?(robot)
  end

  test "starting a robot with a name" do
    {:ok, supervisor} = Hugh.start_robot(TestRobot, name: :carmine)
    assert Process.alive?(supervisor)
    assert robot = Process.whereis(:carmine)
    assert Process.alive?(robot)
  end
end
