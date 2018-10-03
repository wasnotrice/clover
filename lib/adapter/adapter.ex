defmodule Hugh.Adapter do
  defmacro __using__(_args) do
    quote do
      use GenServer

      def init(opts) do
        supervisor = Keyword.fetch!(opts, :supervisor)
        send(self(), :after_init)
        {:ok, %{robot: nil, supervisor: supervisor}}
      end

      def start_link(opts) do
        name = process_name(opts)
        Hugh.Adapter.start_link(__MODULE__, opts, name: name)
      end

      defp process_name(opts) do
        String.to_atom("#{Keyword.fetch!(opts, :name)}.#{process_suffix()}")
      end

      @doc """
      A suffix for this process's name in the local registry.

      If your robot is named `:Mike`, then your adapter will be `:Mike.Adapter`.
      You can override the suffix in your own module.
      """
      def process_suffix, do: "Adapter"

      defoverridable process_suffix: 0

      def handle_info(:after_init, %{supervisor: pid} = state) do
        robot = Hugh.Robot.Supervisor.find_robot(pid)
        {:noreply, %{state | robot: robot}}
      end

      def handle_info(_msg, state) do
        {:noreply, state}
      end
    end
  end

  def start_link(mod, arg, opts) do
    GenServer.start_link(mod, arg, opts)
  end
end
