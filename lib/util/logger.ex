defmodule Hugh.Util.Logger do
  require Logger

  def log(level, message, opts \\ []) do
    good_opts =
      case check_opts(opts) do
        {:ok, good} -> good
        {:error, error} -> raise error
      end

    Logger.log(level, log_message(message, good_opts))
  end

  defp check_opts(opts) do
    valid_keys = [:label, :inspect]

    case Keyword.keys(opts) -- valid_keys do
      [] -> {:ok, opts}
      keys -> {:error, Hugh.Error.exception({:badarg, {__MODULE__, "log options", keys}})}
    end
  end

  def log_message(message, opts) do
    prefix =
      case Keyword.get(opts, :label) do
        nil -> nil
        label -> "[#{label}]"
      end

    postfix =
      case Keyword.get(opts, :inspect) do
        nil -> nil
        thing -> inspect(thing)
      end

    fn ->
      [prefix, message, postfix]
      |> Enum.filter(fn frag -> frag end)
      |> Enum.join(" ")
    end
  end
end
