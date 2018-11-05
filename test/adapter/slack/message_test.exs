defmodule Clover.Adapter.Slack.MessageTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Clover.Adapter.Slack

  alias Clover.{
    Message,
    User
  }

  def slack_message do
    %{
      channel: "C3C3C3C3C",
      client_msg_id: "8f2855bf-0463-4fe8-8b99-b6f451286ff9",
      event_ts: "1538967610.000100",
      team: "T0T0T0T0T",
      text: "<@U9U9U9U9U> hi",
      ts: "1538967610.000100",
      type: "message",
      user: "U8U8U8U8U"
    }
  end

  def robot_context do
    %{
      me: %{
        id: "U9U9U9U9U",
        name: "testbot"
      },
      connection: %{
        users: %{}
      }
    }
  end

  test "from_external" do
    message = Slack.Message.from_external(slack_message(), "alice", robot_context())

    assert message == %Message{
             room: "C3C3C3C3C",
             robot: %{
               name: "alice",
               user: %{
                 id: "U9U9U9U9U",
                 name: "testbot"
               }
             },
             text: "<@U9U9U9U9U> hi",
             type: nil,
             user: %User{
               id: "U8U8U8U8U",
               name: nil
             }
           }
  end
end
