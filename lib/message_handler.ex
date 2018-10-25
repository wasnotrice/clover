defmodule Clover.MessageHandler do
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
  @type handler :: {module :: atom, function :: atom} | function()
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
          respond: handler
        }

  # Descends into the list of handlers, attempting to match the last handler first, to preserve the order in which
  # handlers were declared
  @spec handle_message(Message.t(), mention_format :: Regex.t(), data :: map, [t()] | atom) ::
          response()
  def handle_message(_message, _mention_format, _data, []), do: :noreply

  def handle_message(message, mention_format, data, [handler | []]),
    do: handle(handler, message, mention_format, data)

  def handle_message(message, mention_format, data, [handler | tail]) do
    case handle_message(message, mention_format, data, tail) do
      :nomatch -> handle(handler, message, mention_format, data)
      reply -> reply
    end
  end

  @spec handle(t, Message.t(), Regex.t(), data) :: response
  # If the handler is a module, then skip the match and try all of the modules handlers
  def handle(%__MODULE__{respond: mod}, %Message{} = message, mention_format, data)
      when is_atom(mod) do
    handle_message(message, mention_format, data, mod.message_handlers())
  end

  def handle(%__MODULE__{} = handler, %Message{} = message, mention_format, data) do
    case match(handler, message, mention_format) do
      nil ->
        :nomatch

      match ->
        validated =
          handler
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

  def match(%__MODULE__{match_mode: :overhear} = handler, message, _mention_format) do
    match(handler, message)
  end

  def match(%__MODULE__{match_mode: :respond} = handler, message, mention_format) do
    original_text = message.text

    case Message.trim_leading_mention(message, mention_format) do
      %{text: ^original_text} -> nil
      trimmed -> match(handler, trimmed)
    end
  end

  def match(%__MODULE__{match: regex}, %Message{text: text}) do
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
        {:error, Error.exception({:invalid_message_handler_return, invalid_return})}
    end
  end

  @doc """
  Create a new message handler struct

  ## Examples

  iex> MessageHandler.new(:overhear, ~r/hi/, {SomeModule, :some_function})
  %MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}

  iex> MessageHandler.new(%MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}})
  %MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}

  iex> MessageHandler.new({:overhear, ~r/hi/, {SomeModule, :some_function}})
  %MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}
  """
  def new(%__MODULE__{} = struct), do: struct
  def new(tuple) when is_tuple(tuple), do: from_tuple(tuple)

  def new(mode, match, {mod, fun}) when is_atom(mod) and is_atom(fun) do
    %__MODULE__{match: match, match_mode: mode, respond: {mod, fun}}
  end

  def new(mode, match, handler) when is_atom(handler) do
    %__MODULE__{match: match, match_mode: mode, respond: handler}
  end

  @doc """
  Given a message handler struct, return a tuple

  ## Examples

  iex> MessageHandler.to_tuple(%MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}})
  {:overhear, ~r/hi/, {SomeModule, :some_function}}
  """
  def to_tuple(%__MODULE__{match: match, match_mode: mode, respond: respond}) do
    {mode, match, respond}
  end

  @doc """
  Given a message handler tuple, return a struct

  ## Examples

      iex> MessageHandler.from_tuple({:overhear, ~r/hi/, {SomeModule, :some_function}})
      %MessageHandler{match: ~r/hi/, match_mode: :overhear, respond: {SomeModule, :some_function}}
  """
  def from_tuple({mode, match, respond}) when mode in [:overhear, :respond] do
    %__MODULE__{match: match, match_mode: mode, respond: respond}
  end

  defp log(level, message, opts \\ []) do
    Logger.log(level, "message worker", message, opts)
  end
end
