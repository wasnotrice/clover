defmodule Hugh.Adapter.Slack.Connection do
  use Slack

  alias Hugh.Adapter

  def init(arg) do
    IO.inspect(arg, label: "Slack.Connection")
  end

  def handle_connect(slack, state) do
    IO.puts("Connected to slack as #{slack.me.name}")
    {:ok, state}
  end

  def handle_close(reason, _slack, state) do
    IO.puts("Slack connection closed: #{reason}")
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    send_message("I got a message!", message.channel, slack)
    Adapter.incoming(state.adapter, message)
    {:ok, state}
  end

  def handle_event(event, _, state) do
    IO.inspect(event, label: "slack event")
    {:ok, state}
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts("Sending your message, captain!")

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(message, _, state) do
    IO.puts("Slack info: #{message}")
    {:ok, state}
  end
end
