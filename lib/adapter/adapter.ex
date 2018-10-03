defmodule Hugh.Adapter do
  defmacro __using__(_args) do
    quote do
      use GenServer

      def init(opts) do
        {:ok, %{}}
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
    end
  end

  def start_link(mod, arg, opts) do
    GenServer.start_link(mod, arg, opts)
  end
end
