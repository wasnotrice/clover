defmodule Clover.Script do
  @moduledoc """
  A data structure for handling `Clover.Message`s
  """

  alias Clover.{
    Error,
    Message
  }

  alias Clover.Util.Logger

  import Kernel, except: [match?: 2]

  @type match_mode :: :overhear | :respond
  @type script :: {module :: atom, function :: atom} | function()
  @type data :: term
  @type response ::
          :nomatch
          | :noreply
          | {:noreply, data}
          | Message.t()
          | {Message.t(), data}
          | [Message.t()]
          | :invalid_return

  @enforce_keys [:match, :respond]

  defstruct match: nil,
            match_mode: :respond,
            respond: nil

  @type t :: %__MODULE__{
          match: Regex.t(),
          match_mode: match_mode,
          respond: script
        }

  # Descends into the list of scripts, attempting to match the last script first, to preserve the order in which
  # scripts were declared
  @spec handle_message(Message.t(), data :: map, [t()] | atom) :: response()
  def handle_message(_message, _data, []), do: :noreply

  def handle_message(message, data, [script | []]),
    do: handle(script, message, data)

  def handle_message(message, data, [script | tail]) do
    case handle_message(message, data, tail) do
      :nomatch -> handle(script, message, data)
      reply -> reply
    end
  end

  @spec handle(t, Message.t(), data) :: response
  # If the script is a module, then skip the match and try all of the modules scripts
  def handle(%__MODULE__{respond: mod}, %Message{} = message, data)
      when is_atom(mod) do
    handle_message(message, data, mod.scripts())
  end

  def handle(%__MODULE__{} = script, %Message{} = message, data) do
    case match(script, message) do
      nil ->
        :nomatch

      match ->
        validated =
          script
          |> respond(message, match, data)
          |> validate_response()

        case validated do
          {:ok, response} ->
            response

          {:error, %Error{} = error} ->
            log(:error, Error.message(error))
            :nomatch
        end
    end
  end

  def match(%__MODULE__{match_mode: :overhear} = script, message) do
    match(script.match, message)
  end

  def match(%__MODULE__{match_mode: :respond} = script, message) do
    original_text = message.text

    mention_format = Message.mention_format(message, :me)

    case Message.trim_leading_mention(message, mention_format) do
      %{text: ^original_text} -> nil
      trimmed -> match(script.match, trimmed)
    end
  end

  def match(%Regex{} = regex, %Message{text: text}) do
    case Regex.run(regex, text) do
      nil -> nil
      captures -> %{captures: captures, named_captures: Regex.named_captures(regex, text)}
    end
  end

  def respond(%__MODULE__{respond: {mod, fun}}, message, match, data) do
    apply(mod, fun, [message, match, data])
  end

  @spec validate_response(response) :: {:ok, response} | {:error, %Error{}}
  defp validate_response(response) do
    case response do
      %Message{action: action} when action in [:say, :typing] ->
        {:ok, response}

      {%Message{action: action}, _new_data} when action in [:say, :typing] ->
        {:ok, response}

      messages when is_list(messages) ->
        {:ok, response}

      {:noreply, _new_data} ->
        {:ok, response}

      :noreply ->
        {:ok, response}

      :nomatch ->
        {:ok, response}

      invalid_return ->
        {:error, Error.exception({:invalid_script_return, invalid_return})}
    end
  end

  @doc """
  Create a new script struct

  ## Examples

  iex> Script.new(:overhear, ~r/hi/, {SomeModule, :some_function})
  %Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}

  iex> Script.new(%Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}})
  %Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}

  iex> Script.new({:overhear, ~r/hi/, {SomeModule, :some_function}})
  %Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}
  """
  def new(%__MODULE__{} = struct), do: struct
  def new(tuple) when is_tuple(tuple), do: from_tuple(tuple)

  def new(mode, match, {mod, fun}) when is_atom(mod) and is_atom(fun) do
    %__MODULE__{match: match, match_mode: mode, respond: {mod, fun}}
  end

  def new(mode, match, script) when is_atom(script) do
    %__MODULE__{match: match, match_mode: mode, respond: script}
  end

  @doc """
  Given a script struct, return a tuple

  ## Examples

  iex> Script.to_tuple(%Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}})
  {:overhear, ~r/hi/, {SomeModule, :some_function}}
  """
  def to_tuple(%__MODULE__{match: match, match_mode: mode, respond: respond}) do
    {mode, match, respond}
  end

  @doc """
  Given a script tuple, return a struct

  ## Examples

      iex> Script.from_tuple({:overhear, ~r/hi/, {SomeModule, :some_function}})
      %Script{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}
  """
  def from_tuple({mode, match, respond}) when mode in [:overhear, :respond] do
    %__MODULE__{match: match, match_mode: mode, respond: respond}
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, "message worker", message, opts)
  end
end
