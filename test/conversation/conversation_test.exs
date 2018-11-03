defmodule Clover.ConversationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Clover.Conversation
  alias Clover.Test

  test "new/1" do
    assert %Conversation{transcript: []} = Conversation.new()
  end
end
