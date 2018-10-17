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

  test "messages are handled in separate processes", %{name: name} do
    Adapter.incoming(name, "pid", %{})
    assert_receive({:out, pid})
    refute pid_from_string(pid) == Clover.whereis_robot(name)
  end

  @tag :capture_log
  test "crash in message handler doesn't crash robot", %{name: name} do
    robot = Clover.whereis_robot(name)
    Adapter.incoming(name, "crash", %{})
    Process.sleep(10)
    assert Clover.whereis_robot(name) == robot
  end

  # https://github.com/koudelka/visualixir/blob/master/lib/visualixir/tracer.ex
  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end

  def pid_from_string(string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_atom()
    |> :erlang.whereis()
  end
end
