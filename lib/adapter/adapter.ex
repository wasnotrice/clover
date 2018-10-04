defmodule Hugh.Adapter do
  use GenServer

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Hugh.Adapter

      if Code.ensure_loaded?(Supervisor) and function_exported?(Supervisor, :init, 2) do
        @doc false
        def child_spec(arg, opts \\ []) do
          default = %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [arg, opts]}
          }

          Supervisor.child_spec(default, unquote(Macro.escape(opts)))
        end

        defoverridable child_spec: 2
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
    end
  end

  def start_link(mod, arg, opts) do
    GenServer.start_link(__MODULE__, {mod, arg}, opts)
  end

  def init({mod, arg}) do
    {:ok, state} = mod.init(arg)
    {:ok, Map.put(state, :mod, mod)}
  end

  def connect(adapter, to: robot) do
    GenServer.call(adapter, {:connect_robot, robot})
  end

  def send(adapter, message) do
    GenServer.cast(adapter, {:send, message})
  end

  def incoming(adapter, message) do
    GenServer.cast(adapter, {:incoming, message})
  end

  def handle_call({:connect_robot, robot}, _from, state) do
    new_state = Map.put(state, :robot, robot)
    {:reply, :ok, new_state}
  end

  def handle_cast({:incoming, message}, %{mod: mod} = state) do
    mod.handle_in({:message, message}, state)
    {:noreply, state}
  end

  def handle_cast({:send, message}, %{mod: mod} = state) do
    mod.handle_out({:send, message}, state)
    {:noreply, state}
  end
end
