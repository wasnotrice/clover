defmodule Clover.Adapter.SlackTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Clover.Adapter.Slack

  @user_id "12345"
  @slack_state %{
    users: %{
      @user_id => %{
        name: "bob"
      }
    }
  }

  test "normalize/2" do
    incoming = %{text: "hi there", user: @user_id, channel: "lobby", subtype: nil}
    state = %{robot: "alice s"}

    assert {message, _} = Slack.handle_in({:message, incoming}, state, @slack_state)

    assert message ==
             %Clover.Message{
               robot: "alice s",
               room: "lobby",
               text: "hi there",
               type: nil,
               user: %Clover.User{id: "12345", name: "bob"}
             }
  end
end
