# Make sure Kernel.function_exported?/3 works as expected in tests
Enum.each([Clover.Test.TestRobot, Clover.Test.TestAdapter], fn mod ->
  true = Code.ensure_loaded?(mod)
end)

defmodule Clover.RobotTest do
  use ExUnit.Case, async: true

  alias Clover.Test.{TestAdapter, TestRobot}
  alias Clover.{Adapter, Robot, User}
  alias Clover.Robot.Supervisor, as: RobotSupervisor

  describe "a well-built robot" do
    test "robot responds to message" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "testbot ping", %{})
      assert_receive({:out, "pong"})
    end

    test "robot sends message" do
      name = start_robot!(TestRobot)
      Robot.send(name, "goodbye")
      assert_receive({:out, "goodbye"})
    end

    test "robot receives name" do
      name = start_robot!(TestRobot)
      robot_user = %User{id: "alice", name: "alice"}
      Adapter.connected(name, %{me: robot_user})
      assert Robot.name(name) == "alice"
    end

    test "messages are handled in separate processes" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "testbot pid", %{})
      assert_receive({:out, pid})
      refute pid_from_string(pid) == Clover.whereis_robot(name)
    end

    @tag :capture_log
    test "crash in message handler doesn't crash robot" do
      name = start_robot!(TestRobot)
      robot = Clover.whereis_robot(name)
      Adapter.incoming(name, "testbot crash", %{})
      Process.sleep(10)
      assert Clover.whereis_robot(name) == robot
    end

    @tag :capture_log
    test "bad return value in handler is skipped" do
      name = start_robot!(TestRobot)
      # bad return handler returns "oops", but it's skipped, so nothing matches
      Adapter.incoming(name, "testbot bad return", %{})
      refute_receive({:out, "oops"})
    end

    test "supports named captures in match regex" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "testbot echo halloo down there!", %{})
      assert_receive({:out, "halloo down there!"})
    end

    test "requires leading mention to match respond handler" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "echo halloo down there!", %{})
      refute_receive({:out, "halloo down there!"})
    end

    test "supports function handlers" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "testbot what time is it?", %{})
      assert_receive({:out, "4:30"})
    end

    test "runs handlers in the order they were declared" do
      name = start_robot!(TestRobot)
      Adapter.incoming(name, "testbot echo ping", %{})
      assert_receive({:out, "ping"})
    end

    test "assigns handlers" do
      handlers = TestRobot.message_handlers()

      assert Enum.find(handlers, fn x ->
               x.match == ~r/ping/ and x.match_mode == :respond and
                 x.respond == {Clover.Test.TestRobot, :ping_handler}
             end)
    end
  end

  defmodule BadRobot do
    use Clover.Robot
  end

  describe "a robot with nothing defined" do
    # test "does not respond to message", %{name: name} do
    #   name = unique_name()
    #   start_robot!(name, BadRobot)
    #   Adapter.incoming(name, "ping", %{})
    #   refute_receive({:out, "pong"})
    # end
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
