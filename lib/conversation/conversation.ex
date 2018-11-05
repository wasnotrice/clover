defmodule Clover.Conversation do
  @moduledoc """
  A multi-message conversation

  A `Clover.Conversation` happens in a `Clover.Room` between a robot and a `Clover.User`.
  """

  use GenServer

  alias Clover.{
    Message,
    Script
  }

  alias Clover.Conversation.Supervisor, as: ConversationSupervisor

  defstruct assigns: %{},
            transcript: []

  @type t :: %__MODULE__{
          assigns: map,
          transcript: [Message.t()]
        }

  def new do
    %__MODULE__{}
  end

  def start_link(message, opts \\ []) do
    name = Keyword.get(opts, :name, via_tuple(message))
    GenServer.start_link(__MODULE__, message, name: name)
  end

  def init(message) do
    state = %__MODULE__{assigns: %{}, transcript: [message]}
    {:ok, state}
  end

  def start(message) do
    ConversationSupervisor.start_link(message)
  end

  def incoming(message, scripts) do
    case Clover.whereis_conversation(message) do
      nil ->
        {:error, :invalid_conversation}

      conversation ->
        GenServer.call(conversation, {:incoming, message, scripts})
    end
  end

  def handle_call({:incoming, message, scripts}, _from, state) do
    response = Script.handle_message(message, %{}, scripts)
    {:reply, response, state}
  end

  def via_tuple(message) do
    robot = Message.robot(message)
    room = Message.room(message)
    user = Message.user(message)

    {:via, Registry, {Clover.registry(), {robot, :conversation, room, user}}}
  end
end
