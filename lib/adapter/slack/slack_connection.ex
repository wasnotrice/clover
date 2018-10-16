defmodule Clover.Adapter.Slack.Connection do
  @moduledoc false

  use Slack

  alias Clover.{
    Adapter,
    User
  }

  alias Clover.Util.Logger

  def handle_connect(slack, state) do
    log(:debug, "connected as #{slack.me.name}")

    connection_state = %{
      me: %User{
        id: slack.me.id,
        name: slack.me.name
      }
    }

    Adapter.connected(state.robot, connection_state)
    {:ok, state}
  end

  def handle_close(reason, _slack, state) do
    log(:debug, "connection closed", inspect: reason)
    {:ok, state}
  end

  def handle_event(%{type: "message"} = message, slack, state) do
    Adapter.incoming(state.robot, message, slack)
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
    Logger.log(level, "slack", message, opts)
  end
end
