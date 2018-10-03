defmodule Hugh.Adapter do
  defmacro __using__(_args) do
    quote do
      use GenServer

      def start_link(args) do
        Hugh.Adapter.start_link(__MODULE__, args)
      end
    end
  end

  def start_link(mod, args) do
    GenServer.start_link(mod, {self(), args})
  end
end
