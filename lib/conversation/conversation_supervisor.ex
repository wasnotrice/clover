defmodule Clover.Conversation.Supervisor do
  @moduledoc false

  alias Clover.{
    Conversation,
    Message
  }

  def start_link(message, robot) do
    name = message |> Message.robot() |> via_tuple
    DynamicSupervisor.start_child(name, {Conversation, {message, robot}})
  end

  def via_tuple(name) do
    {:via, Registry, {Clover.registry(), {name, :conversations}}}
  end
end
