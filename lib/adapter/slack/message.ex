defmodule Hugh.Adapter.Slack.Message do
  @behaviour Hugh.Adapter.Message

  alias Hugh.{
    Message,
    User
  }

  @impl Hugh.Adapter.Message
  def from_external(slack, robot, context) do
    user_id = slack[:user]

    %Message{
      robot: robot,
      room: slack[:channel],
      text: slack[:text],
      type: slack[:subtype],
      user: %User{id: user_id, name: get_in(context, [:users, :user_id, :name])}
    }
  end

  @impl Hugh.Adapter.Message
  def to_external(%Message{text: text, room: channel}) do
    {text, channel}
  end
end
