defmodule Clover.Util.Logger do
  @moduledoc false
  require Logger

  @keys [:inspect]

  def log(level, label, message, opts \\ []) do
    options = Enum.reduce(opts, %{}, &extract_option/2)
    Logger.log(level, log_message(label, message, options))
  end

  defp extract_option({:inspect, thing}, options) do
    Map.put(options, :inspect, thing)
  end

  defp extract_option({key, _}, _) do
    {:error, Clover.Error.exception({:badarg, {__MODULE__, "log option", key, @keys}})}
  end

  def log_message(label, message, opts) do
    fn ->
      prefix =
        case label do
          nil -> nil
          label -> "[#{label}]"
        end

      postfix =
        case Map.get(opts, :inspect) do
          nil -> nil
          thing -> inspect(thing)
        end

      [prefix, message, postfix]
      |> Enum.filter(& &1)
      |> Enum.join(" ")
    end
  end
end
