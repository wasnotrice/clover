defmodule Hugh.Adapter.Slack.MessageTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Hugh.Adapter.Slack

  alias Hugh.{
    Message,
    User
  }

  def slack do
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

  def context do
    %{
      me: %{
        id: "U9U9U9U9U"
      },
      users: %{}
    }
  end

  test "from_external" do
    message = Slack.Message.from_external(slack(), self(), context())

    assert message == %Message{
             mentions: %{
               "U9U9U9U9U" => {0, 12}
             },
             room: "C3C3C3C3C",
             robot: self(),
             text: "<@U9U9U9U9U> hi",
             type: nil,
             user: %User{
               id: "U8U8U8U8U",
               name: nil
             }
           }
  end
end
