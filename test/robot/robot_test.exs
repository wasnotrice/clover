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
      name = "doug"
      start_robot!(name, TestRobot)
      Adapter.incoming(name, "ping", %{})
      assert_receive({:out, "pong"})
    end

    test "robot sends message" do
      name = "ethel"
      start_robot!(name, TestRobot)
      Robot.send(name, "goodbye")
      assert_receive({:out, "goodbye"})
    end

    test "robot receives name" do
      name = "frida"
      start_robot!(name, TestRobot)
      robot_user = %User{id: "alice", name: "alice"}
      Adapter.connected(name, %{me: robot_user})
      assert Robot.name(name) == "alice"
    end

    test "messages are handled in separate processes" do
      name = "gary"
      start_robot!(name, TestRobot)
      Adapter.incoming(name, "pid", %{})
      assert_receive({:out, pid})
      refute pid_from_string(pid) == Clover.whereis_robot(name)
    end

    @tag :capture_log
    test "crash in message handler doesn't crash robot" do
      name = "hank"
      start_robot!(name, TestRobot)
      robot = Clover.whereis_robot(name)
      Adapter.incoming(name, "crash", %{})
      Process.sleep(10)
      assert Clover.whereis_robot(name) == robot
    end

    @tag :capture_log
    test "bad return value in handler is skipped" do
      name = "ida"
      start_robot!(name, TestRobot)
      # bad return handler returns "oops", but it's skipped, so nothing matches
      Adapter.incoming(name, "bad return", %{})
      refute_receive({:out, "oops"})
    end

    test "supports named captures in match regex" do
      name = "jane"
      start_robot!(name, TestRobot)
      Adapter.incoming(name, "testbot echo halloo down there!", %{})
      assert_receive({:out, "halloo down there!"})
    end

    test "runs handlers in the order they were declared" do
      name = "ken"
      start_robot!(name, TestRobot)
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
    #   name = "joe"
    #   start_robot!(name, BadRobot)
    #   Adapter.incoming(name, "ping", %{})
    #   refute_receive({:out, "pong"})
    # end
  end

  def start_robot!(name, robot) do
    child_spec = RobotSupervisor.child_spec({name, {robot, []}, {TestAdapter, sink: self()}}, [])
    start_supervised!(child_spec)
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
