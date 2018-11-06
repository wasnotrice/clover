defmodule Clover.Adapter.SlackTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Clover.Adapter.Slack

  alias Clover.{
    Message,
    User
  }

  @user_id "U8U8U8U8U"
  @me_id "U9U9U9U9U"
  @me %User{
    id: @me_id,
    name: "testbot"
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
    slack_message = %{
      channel: "C3C3C3C3C",
      client_msg_id: "8f2855bf-0463-4fe8-8b99-b6f451286ff9",
      event_ts: "1538967610.000100",
      team: "T0T0T0T0T",
      text: "<@U9U9U9U9U> hi",
      ts: "1538967610.000100",
      type: "message",
      user: "U8U8U8U8U"
    }

    state = %{name: "alice", me: @me, connection: @slack_state}

    message = Slack.normalize(slack_message, state)

    assert Message.me(message) == @me
    assert Message.mention_format(message, :me) == ~r/<@(#{@me_id})>/
    assert Message.mention_format(message, :any) == ~r/<@(\w+)>/
    assert Message.robot(message) == "alice"
    assert Message.room(message) == slack_message.channel
    assert Message.text(message) == slack_message.text
    assert Message.type(message) == nil
    assert Message.user(message) == %Clover.User{id: slack_message.user, name: "bob"}
  end
end
