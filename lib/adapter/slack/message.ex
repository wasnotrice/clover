defmodule Clover.Adapter.Slack.Message do
  @moduledoc """
  Conversion functions for transforming Slack messages into Clover messages and vice versa.
  """
  @behaviour Clover.Adapter.Message

  alias Clover.{
    Message,
    User
  }

  @impl Clover.Adapter.Message
  def from_external(slack, robot, context) do
    user_id = slack[:user]
    text = slack[:text]

    %Message{
      robot: robot,
      room: slack[:channel],
      text: text,
      type: slack[:subtype],
      user: %User{id: user_id, name: get_in(context, [:users, user_id, :name])}
    }
  end

  @impl Clover.Adapter.Message
  def to_external(%Message{text: text, room: channel}) do
    {text, channel}
  end
end
