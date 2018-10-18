true = Code.ensure_loaded?(Clover.Test.TestAdapter)

defmodule Clover.AdapterTest do
  use ExUnit.Case, async: true

  alias Clover.Adapter
  alias Clover.Test.TestAdapter

  defmodule BadAdapter do
    use Clover.Adapter
  end

  describe "an adapter with nothing defined" do
    test "fails to start" do
      name = "kelly a"

      assert_raise(
        RuntimeError,
        ~r/failed to start.+Reason:.+:undef.+Clover.AdapterTest.BadAdapter.+handle_in: 3/ms,
        fn ->
          start_adapter!(name, Clover.AdapterTest.BadAdapter)
        end
      )
    end
  end

  describe "a good adapter" do
    test "sends message" do
      name = "larry a"

      Registry.register(Clover.registry(), name, [])
      assert Clover.whereis_robot(name) == self()

      start_adapter!(name, TestAdapter, sink: self())
      assert is_pid(Clover.whereis_robot_adapter(name))

      Process.sleep(50)

      Adapter.incoming(name, "ping", %{})
      assert_receive({:out, "pong"})
    end
  end

  def start_adapter!(name, adapter, arg \\ []) do
    child = Adapter.child_spec({name, adapter, arg}, name: Adapter.via_tuple(name))
    start_supervised!(child)
  end

  def assert_receive_genserver_call do
    assert_receive({:"$gen_call", {_, _}, _message})
  end
end
