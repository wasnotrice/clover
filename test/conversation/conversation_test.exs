# Make sure Kernel.function_exported?/3 works as expected in tests
Enum.each([Clover.Test.TestRobot, Clover.Test.TestAdapter], fn mod ->
  true = Code.ensure_loaded?(mod)
end)

defmodule Clover.ConversationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Clover.{
    Conversation,
    User
  }

  alias Clover.Test.{TestAdapter, TestRobot}

  @message TestAdapter.normalize("hi", %{
             name: "doris",
             me: %User{name: "testrobot", id: "robot123"}
           })

  test "new/1" do
    assert %Conversation{transcript: []} = Conversation.new()
  end

  describe "registry" do
    setup :start_conversation!

    test "registry", %{pid: pid} do
      assert ^pid = Clover.whereis_conversation(@message)
    end
  end

  describe "scripts/1" do
    setup :start_conversation!

    test "returns scripts", %{pid: pid} do
      scripts = Conversation.scripts(pid)
      assert Enum.count(scripts) > 5
    end
  end

  describe "transcript/1" do
    setup :start_conversation!

    test "starts with no messages", %{pid: pid} do
      [] = Conversation.transcript(pid)
    end
  end

  describe "incoming/2" do
    setup :start_conversation!

    test "stores messages", %{pid: pid} do
      response = Conversation.incoming(pid, @message)
      [^response, @message] = Conversation.transcript(pid)
      ^response = Conversation.incoming(pid, @message)
      [^response, @message, ^response, @message] = Conversation.transcript(pid)
    end
  end

  def start_conversation!(_) do
    pid = start_supervised!({Conversation, {@message, TestRobot}})
    {:ok, pid: pid}
  end
end
