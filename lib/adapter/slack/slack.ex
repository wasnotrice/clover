defmodule Clover.Adapter.Slack do
  @moduledoc """
  A `Clover.Adapter` for Slack
  """
  use Clover.Adapter

  alias Slack.Bot, as: SlackBot

  @doc false
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
  def handle_in({:message, message}, state, context) do
    {:message, __MODULE__.Message.from_external(message, state.robot, context), state}
  end

  @impl Clover.Adapter

  def handle_out({:send, message}, %{connection: connection}) do
    {text, channel} = __MODULE__.Message.to_external(message)
    Kernel.send(connection, {:message, text, channel})
  end
end
