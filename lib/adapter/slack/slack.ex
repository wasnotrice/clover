defmodule Clover.Adapter.Slack do
  @moduledoc """
  A `Clover.Adapter` for Slack
  """
  use Clover.Adapter

  alias Clover.User
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
  def normalize({:message, message}, context) do
    __MODULE__.Message.from_external(message, context.robot, context)
  end

  @impl Clover.Adapter

  def handle_out(%{action: :say} = message, %{connection: connection}) do
    {text, channel} = __MODULE__.Message.to_external(message)
    Kernel.send(connection, {:say, text, channel})
  end

  def handle_out(%{action: :typing} = message, %{connection: connection}) do
    {_, channel} = __MODULE__.Message.to_external(message)
    Kernel.send(connection, {:typing, channel})
  end

  @impl Clover.Adapter
  def mention_format, do: ~r/<@(\w+)>/

  @impl Clover.Adapter
  def mention_format(%User{id: id}), do: ~r/<@(#{id})>/
end
