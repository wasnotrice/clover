defmodule Clover.Adapter do
  @moduledoc """
  A Behaviour for `Clover` chat platform adapters.
  """
  use GenServer

  alias Clover.{
    Message
  }

  @type context :: map
  @type state :: map

  @callback handle_out(message :: Message.t(), state) :: {Message.t(), state}
  @callback init(arg :: any, state) :: {:ok, state()}

  @doc """
  Converts a raw incoming message into a `Clover.Message` struct
  """

  @callback normalize(message :: any(), context) :: Message.t()

  @doc """
  Classifies an incoming message by message type
  """
  @callback classify(Message.t(), context) :: Message.t()

  @doc """
  A regex for detecting any mention in message text. Optional.
  """
  @callback mention_format() :: Regex.t()

  @doc """
  A regex for detecting a mention of `user` in message text. Required.
  """
  @callback mention_format(user :: Clover.User.t()) :: Regex.t()

  @optional_callbacks [
    init: 2,
    mention_format: 0,
    classify: 2
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Clover.Adapter
    end
  end

  @doc false
  def child_spec(arg, opts \\ []) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg, opts]}
    }

    Supervisor.child_spec(default, [])
  end

  def start_link(arg, opts) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  @doc false
  def init({robot, robot_mod, mod, arg}) do
    cond do
      !function_exported?(mod, :handle_out, 2) ->
        {:stop, {:undef, mod, handle_out: 2}}

      !function_exported?(mod, :normalize, 2) ->
        {:stop, {:undef, mod, normalize: 2}}

      true ->
        []

        state = %{
          mod: mod,
          robot: robot,
          robot_mod: robot_mod
        }

        if function_exported?(mod, :init, 2) do
          mod.init(arg, state)
        else
          {:ok, state}
        end
    end
  end

  def outgoing(robot_name, message) do
    cast(robot_name, {:outgoing, message})
  end

  # defp call(robot_name, message) do
  #   robot_name
  #   |> Clover.whereis_robot_adapter()
  #   |> GenServer.call(message)
  # end

  defp cast(robot_name, message) do
    robot_name
    |> Clover.whereis_robot_adapter()
    |> GenServer.cast(message)
  end

  def via_tuple(robot_name) do
    {:via, Registry, {Clover.registry(), {robot_name, :adapter}}}
  end

  @doc false
  def handle_cast({:outgoing, message}, %{mod: mod} = state) do
    if function_exported?(mod, :handle_out, 2) do
      log(:debug, "Adapter calling #{mod}.handle_out({#{inspect(message)}}, #{inspect(state)})")
      mod.handle_out(message, state)
      {:noreply, state}
    else
      log(:warn, Clover.format_error({:not_exported, {mod, :handle_out, 2}}))
      {:noreply, state}
    end
  end

  defp log(level, message, opts \\ []) do
    alias Clover.Util.Logger
    Logger.log(level, "adapter", message, opts)
  end
end
