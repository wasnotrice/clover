defmodule Hugh.Adapter.Slack do
  use Hugh.Adapter

  def start_link(arg, opts \\ []) do
    Hugh.Adapter.start_link(__MODULE__, arg, opts)
  end

  def init(opts, state) do
    token = Keyword.fetch!(opts, :token)

    case Slack.Bot.start_link(Hugh.Adapter.Slack.Connection, %{adapter: self()}, token, %{
           name: :slack
         }) do
      {:ok, connection} ->
        Process.monitor(connection)
        {:ok, state}

      error ->
        error
    end

    {:ok, state}
  end

  @impl Hugh.Adapter
  def handle_in({:message, message}, _state) do
    message
  end

  @impl Hugh.Adapter

  def handle_out({:send, message}, %{sink: sink} = state) do
    Kernel.send(sink, {:out, message})
    {:noreply, state}
  end
end
