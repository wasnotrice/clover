defmodule Hugh.Adapter.Slack do
  use Hugh.Adapter

  alias Hugh.Adapter

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
        {:ok, Map.put(state, :connection, connection)}

      error ->
        error
    end
  end

  @impl Hugh.Adapter
  def handle_in({:message, message}, state, context) do
    {:ok, __MODULE__.Message.from_external(message, state.robot, context), state}
  end

  @impl Hugh.Adapter

  def handle_out({:send, message}, %{connection: connection}) do
    {text, channel} = __MODULE__.Message.to_external(message)
    Kernel.send(connection, {:message, text, channel})
  end
end
