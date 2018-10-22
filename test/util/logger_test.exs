defmodule Clover.Util.LoggerTest do
  use ExUnit.Case, async: true

  alias Clover.Util.Logger

  describe "log_message/3" do
    test "with value to inspect" do
      fun = Logger.log_message("my component", "did a thing", %{inspect: %{with: "this"}})
      assert fun.() == ~s([my component] did a thing %{with: "this"})
    end

    test "minimal" do
      fun = Logger.log_message(nil, "a thing occurred", %{})
      assert fun.() == "a thing occurred"
    end
  end

  describe "log/4" do
    test "raises on bad option" do
      assert_raise Clover.Error, ~r/invalid option/, fn ->
        Logger.log(:info, "my component", "did a thing", inspect: %{with: "this"}, and: "this")
      end
    end
  end
end
