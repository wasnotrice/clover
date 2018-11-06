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
            scripts: [],
            transcript: []

  @type t :: %__MODULE__{
          assigns: map,
          scripts: [Script.t()],
          transcript: [Message.t()]
        }

  def new do
    %__MODULE__{}
  end

  def start_link({message, _scripts} = arg, opts \\ []) do
    name = Keyword.get(opts, :name, via_tuple(message))
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  def init({message, scripts}) do
    state = %__MODULE__{assigns: %{}, scripts: scripts, transcript: [message]}
    {:ok, state}
  end

  def start(message, scripts) do
    ConversationSupervisor.start_link(message, scripts)
  end

  def incoming(message) do
    case Clover.whereis_conversation(message) do
      nil ->
        {:error, :invalid_conversation}

      conversation ->
        GenServer.call(conversation, {:incoming, message})
    end
  end

  def handle_call({:incoming, message}, _from, %{scripts: scripts} = state) do
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
