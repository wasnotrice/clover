defmodule Hugh.Adapter.Slack.Message do
  @behaviour Hugh.Adapter.Message

  alias Hugh.{
    Message,
    User
  }

  @impl Hugh.Adapter.Message
  def from_external(slack, robot, context) do
    user_id = slack[:user]
    text = slack[:text]

    mentions = extract_mentions(text)

    %Message{
      mentions: mentions,
      robot: robot,
      room: slack[:channel],
      text: text,
      type: slack[:subtype],
      user: %User{id: user_id, name: get_in(context, [:users, :user_id, :name])}
    }
  end

  @impl Hugh.Adapter.Message
  def to_external(%Message{text: text, room: channel}) do
    {text, channel}
  end

  defp extract_mentions(nil), do: %{}

  defp extract_mentions(text) do
    regex = ~r/<@(\w+)>/

    case Regex.scan(regex, text, return: :index) do
      nil ->
        %{}

      [] ->
        %{}

      matches ->
        Enum.reduce(matches, %{}, fn [match, {id_start, id_len}], result ->
          id = String.slice(text, id_start, id_len)
          Map.put(result, id, match)
        end)
    end
  end
end
