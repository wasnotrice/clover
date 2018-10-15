defmodule Clover.Adapter.Slack do
  use Clover.Adapter

  alias Clover.Adapter

  def start_link(arg, opts \\ []) do
    Clover.Adapter.start_link(__MODULE__, arg, opts)
  end

  @doc false
  def init(opts, %{robot: robot} = state) do
    token = Keyword.fetch!(opts, :token)

    case Slack.Bot.start_link(Clover.Adapter.Slack.Connection, %{robot: robot}, token) do
      {:ok, connection} ->
        Process.monitor(connection)
        {:ok, Map.put(state, :connection, connection)}

      error ->
        error
    end
  end

  @impl Clover.Adapter
  def handle_in({:message, message}, state, context) do
    {:ok, __MODULE__.Message.from_external(message, state.robot, context), state}
  end

  @impl Clover.Adapter

  def handle_out({:send, message}, %{connection: connection}) do
    {text, channel} = __MODULE__.Message.to_external(message)
    Kernel.send(connection, {:message, text, channel})
  end
end
