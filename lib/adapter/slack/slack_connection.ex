defmodule Hugh.Adapter.Slack.Connection do
  use Slack

  alias Hugh.Adapter
  alias Hugh.Util.Logger

  def handle_connect(slack, state) do
    log(:debug, "connected as #{slack.me.name}")
    {:ok, state}
  end

  def handle_close(reason, _slack, state) do
    log(:debug, "connection closed", inspect: reason)
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    Adapter.incoming(state.adapter, message, slack)
    {:ok, state}
  end

  def handle_event(event, _, state) do
    log(:debug, "event", inspect: event)
    {:ok, state}
  end

  def handle_info({:message, text, channel}, slack, state) do
    send_message(text, channel, slack)
    {:ok, state}
  end

  def handle_info(message, _, state) do
    log(:debug, "info", inspect: message)
    {:ok, state}
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, message, Keyword.put(opts, :label, "slack"))
  end
end
