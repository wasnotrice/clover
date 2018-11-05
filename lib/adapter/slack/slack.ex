defmodule Clover.Adapter.Slack do
  @moduledoc """
  A `Clover.Adapter` for Slack
  """
  use Clover.Adapter

  alias Clover.{
    Message,
    User
  }

  alias Slack.Bot, as: SlackBot

  @doc false
  @impl Clover.Adapter
  def init(opts, %{robot: robot} = state) do
    token = Keyword.fetch!(opts, :token)

    case SlackBot.start_link(Clover.Adapter.Slack.Connection, %{robot: robot}, token) do
      {:ok, connection} ->
        Process.monitor(connection)
        {:ok, Map.put(state, :connection, connection)}

      error ->
        error
    end
  end

  @impl Clover.Adapter
  def normalize(message, context) do
    %{user: user_id, text: text} = message
    %{connection: connection, me: me, name: robot} = context

    Message.new(%{
      me: me,
      robot: robot,
      mention_format_any: mention_format(),
      mention_format_me: mention_format(me),
      room: message[:channel],
      text: text,
      type: message[:subtype],
      user: %User{id: user_id, name: get_in(connection, [:users, user_id, :name])}
    })
  end

  def to_external(%Message{text: text, room: channel}) do
    {text, channel}
  end

  @impl Clover.Adapter
  def handle_out(%{action: :say} = message, %{connection: connection}) do
    {text, channel} = to_external(message)
    Kernel.send(connection, {:say, text, channel})
  end

  def handle_out(%{action: :typing} = message, %{connection: connection}) do
    {_, channel} = to_external(message)
    Kernel.send(connection, {:typing, channel})
  end

  @impl Clover.Adapter
  def mention_format, do: ~r/<@(\w+)>/

  @impl Clover.Adapter
  def mention_format(%User{id: id}), do: ~r/<@(#{id})>/
end
