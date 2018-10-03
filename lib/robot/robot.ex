defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]

  defmacro __using__(opts \\ []) do
    quote do
      use GenStateMachine,
        callback_mode:
          unquote(Keyword.get(opts, :callback_mode, [:handle_event_function, :state_enter]))

      def init(opts) do
        supervisor = Keyword.fetch!(opts, :supervisor)
        state = Keyword.get(opts, :state, :uninitialized)

        data =
          %{supervisor: supervisor, adapter: nil}
          |> Map.merge(Keyword.get(opts, :data, []) |> Enum.into(%{}))

        actions = [{:next_event, :internal, :after_init}]
        {:ok, state, data, actions}
      end

      defoverridable init: 1

      def start_link(opts) do
        name = Keyword.fetch!(opts, :name)
        GenStateMachine.start_link(__MODULE__, opts, name: name)
      end

      def handle_event(:internal, :after_init, _state, %{supervisor: pid} = data) do
        adapter = Hugh.Robot.Supervisor.find_adapter(pid)
        {:next_state, :initialized, %{data | adapter: adapter}}
      end

      def handle_event(:cast, {:incoming, message}, state, data) do
        IO.inspect(message, label: "robot in")
      end

      # def handle_event(type, event, state, data) do
      #   IO.inspect(%{type: type, event: event}, label: "robot received")
      #   :keep_state_and_data
      # end
    end
  end

  def send(robot, message) do
    GenStateMachine.cast(robot, {:send, message})
  end

  def handle_in(robot, message) do
    GenStateMachine.cast(robot, {:incoming, message})
  end
end
