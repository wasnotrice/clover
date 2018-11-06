defmodule Clover.Conversation do
  @moduledoc """
  A multi-message conversation

  A `Clover.Conversation` happens in a `Clover.Room` between a robot and a `Clover.User`.
  """

  use GenServer

  alias Clover.{
    Message,
    Robot,
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

  @spec start_link({message :: Message.t(), robot :: module}, keyword) :: GenServer.on_start()
  def start_link({message, _robot} = arg, opts \\ []) do
    name = Keyword.get(opts, :name, via_tuple(message))
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  def init({_message, robot}) do
    scripts = Robot.scripts(robot)
    state = %__MODULE__{assigns: %{}, scripts: scripts}
    {:ok, state}
  end

  @spec start(message :: Message.t(), robot :: module) :: GenServer.on_start()
  def start(message, robot) do
    ConversationSupervisor.start_link(message, robot)
  end

  def incoming(conversation, message) do
    GenServer.call(conversation, {:incoming, message})
  end

  def scripts(conversation) do
    GenServer.call(conversation, :scripts)
  end

  def transcript(conversation) do
    GenServer.call(conversation, :transcript)
  end

  def handle_call({:incoming, message}, _from, state) do
    response = Script.handle_message(message, state, state.scripts)
    transcript = [response, message | state.transcript]
    state = Map.put(state, :transcript, transcript)
    {:reply, response, state}
  end

  def handle_call(:scripts, _from, %{scripts: scripts} = state) do
    {:reply, scripts, state}
  end

  def handle_call(:transcript, _from, %{transcript: transcript} = state) do
    {:reply, transcript, state}
  end

  def via_tuple(message) do
    robot = Message.robot(message)
    room = Message.room(message)
    user = Message.user(message)

    {:via, Registry, {Clover.registry(), {robot, :conversation, room, user}}}
  end
end
