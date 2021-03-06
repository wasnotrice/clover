# Make sure Kernel.function_exported?/3 works as expected in tests
Enum.each([Clover.Test.TestRobot, Clover.Test.TestAdapter], fn mod ->
  true = Code.ensure_loaded?(mod)
end)

defmodule Clover.RobotTest do
  use ExUnit.Case, async: true

  alias Clover.Test.{TestAdapter, TestRobot}
  alias Clover.{Message, Robot, User}
  alias Clover.Robot.Supervisor, as: RobotSupervisor

  test "robot responds to message" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot ping", %{})
    assert_receive({:say, "pong"})
  end

  test "robot sends message" do
    name = start_robot!(TestRobot)
    Robot.outgoing(name, Message.say(%Message{}, "goodbye"))
    assert_receive({:say, "goodbye"})
  end

  test "robot receives name" do
    name = start_robot!(TestRobot)
    robot_user = %User{id: "alice", name: "alice"}
    Robot.connected(name, %{me: robot_user})
    assert Robot.name(name) == "alice"
  end

  test "messages are handled in separate processes" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot pid", %{})
    assert_receive({:say, pid})
    refute pid_from_string(pid) == Clover.whereis_robot(name)
  end

  @tag :capture_log
  test "crash in script doesn't crash robot" do
    name = start_robot!(TestRobot)
    robot = Clover.whereis_robot(name)
    Robot.incoming(name, "testbot crash", %{})
    Process.sleep(10)
    assert Clover.whereis_robot(name) == robot
  end

  @tag :capture_log
  test "bad return value in script is skipped" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot bad return", %{})
    refute_receive({:say, "oops"})
    assert_receive({:say, "rescued bad return"})
  end

  test "supports named captures in match regex" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot echo halloo down there!", %{})
    assert_receive({:say, "halloo down there!"})
  end

  test "stores value in robot state" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot what number am I?")
    assert_receive({:say, "you are number 1"})
    assert Robot.assigns(name).number == 1
    Robot.incoming(name, "testbot what number am I?")
    assert_receive({:say, "you are number 2"})
  end

  test "requires leading mention to match 'respond' script" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "echo halloo down there!", %{})
    refute_receive({:say, "halloo down there!"})
  end

  # Don't use the `type` script because its delay is too long :)
  test "emits typing event" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot quicktype the quick brown fox", %{})
    assert_receive(:typing)
    assert_receive({:say, "the quick brown fox"})
  end

  test "supports block syntax for direct messages" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot what time is it?", %{})
    assert_receive({:say, "4:30"})
  end

  test "supports block syntax for overheard messages" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "what day is it?", %{})
    assert_receive({:say, "Every day is like Sunday"})
  end

  test "supports module syntax for scripts" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot hex encode 255", %{})
    assert_receive({:say, "FF"})
    Robot.incoming(name, "testbot hex encode my face", %{})
    assert_receive({:say, ~s(I can't encode "my face". Is it an integer?)})
    Robot.incoming(name, "testbot hex decode ff", %{})
    assert_receive({:say, "255"})
    Robot.incoming(name, "testbot hex decode fg", %{})
    assert_receive({:say, ~s(I can't decode "fg". Is it a hex string?)})
  end

  test "supports overhearing" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "hello everyone", %{})
    assert_receive({:say, "hi"})
  end

  test "runs scripts in the order they were declared" do
    name = start_robot!(TestRobot)
    Robot.incoming(name, "testbot echo ping", %{})
    assert_receive({:say, "ping"})
  end

  test "assigns scripts" do
    scripts = TestRobot.scripts()

    assert Enum.find(scripts, fn x ->
             x.match == ~r/ping/ and x.match_mode == :respond and
               x.respond == {Clover.Test.TestRobot, :ping_script}
           end)
  end

  def start_robot!(robot) do
    name = unique_name()
    child_spec = RobotSupervisor.child_spec({name, {robot, []}, {TestAdapter, sink: self()}}, [])
    _pid = start_supervised!(child_spec)
    name
  end

  def unique_name do
    "testbot-#{System.unique_integer([:positive, :monotonic])}"
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
