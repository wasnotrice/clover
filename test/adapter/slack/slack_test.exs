defmodule Clover.Adapter.SlackTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Clover.Adapter.Slack
  alias Clover.User

  @user_id "12345"
  @me_id "r0b0t"
  @me %{
    id: @me_id,
    name: "robot"
  }
  @slack_state %{
    me: @me,
    users: %{
      @user_id => %{
        name: "bob"
      }
    }
  }

  test "normalize/2" do
    incoming = %{text: "hi there", user: @user_id, channel: "lobby", subtype: nil}
    state = %{robot: "alice", me: @me, connection: @slack_state}

    assert Slack.normalize(incoming, state) ==
             %Clover.Message{
               robot: %{
                 name: "alice",
                 user: @me
               },
               room: "lobby",
               text: "hi there",
               type: nil,
               user: %Clover.User{id: "12345", name: "bob"}
             }
  end
end
