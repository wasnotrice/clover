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
        state = Keyword.get(opts, :state, :disconnected)
        data = Keyword.get(opts, :data, %{})
        {:ok, state, data}
      end

      defoverridable init: 1

      def start_link(opts) do
        name = Keyword.fetch!(opts, :name)
        GenStateMachine.start_link(__MODULE__, opts, name: name)
      end
    end
  end
end
