defmodule Hugh.Robot do
  @moduledoc """
  A Robot.
  """

  @type state :: :normal
  @type data :: map
  @type action :: GenStateMachine.action()
  @type actions :: [action]

  defmacro __using__(_args) do
    quote do
      use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

      def init(args) do
        {:ok, Keyword.get(args, :state, :disconnected), Keyword.get(args, :data, %{})}
      end

      defoverridable init: 1

      def start_link(args) do
        opts = [name: Keyword.get(args, :name, __MODULE__)]
        GenStateMachine.start_link(__MODULE__, args, opts)
      end
    end
  end
end
