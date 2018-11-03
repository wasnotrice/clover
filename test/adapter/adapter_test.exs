true = Code.ensure_loaded?(Clover.Test.TestAdapter)
true = Code.ensure_loaded?(Clover.Test.NoHandleInAdapter)
true = Code.ensure_loaded?(Clover.Test.NoHandleOutAdapter)
true = Code.ensure_loaded?(Clover.Test.NoInitAdapter)

defmodule Clover.AdapterTest do
  use ExUnit.Case, async: true

  alias Clover.Adapter

  describe "bad adapters" do
    test "when handle_in/3 is undefined, fails to start" do
      name = "kelly a"

      assert_raise(
        RuntimeError,
        ~r/failed to start.+Reason:.+:undef.+Clover.Test.NoHandleInAdapter.+handle_in: 3/ms,
        fn ->
          start_adapter!(name, Clover.Test.NoHandleInAdapter)
        end
      )
    end

    test "when handle_out/2 is undefined, fails to start" do
      name = "mary a"

      assert_raise(
        RuntimeError,
        ~r/failed to start.+Reason:.+:undef.+Clover.Test.NoHandleOutAdapter.+handle_out: 2/ms,
        fn ->
          start_adapter!(name, Clover.Test.NoHandleOutAdapter)
        end
      )
    end

    test "when init/2 is undefined, starts" do
      name = "nancy a"
      pid = start_adapter!(name, Clover.Test.NoInitAdapter)
      assert is_pid(pid)
    end
  end

  def start_adapter!(name, adapter, arg \\ []) do
    child =
      Adapter.child_spec({name, Clover.Test.TestRobot, adapter, arg},
        name: Adapter.via_tuple(name)
      )

    start_supervised!(child)
  end
end
