defmodule Clover.MessageHandler do
  @moduledoc """
  A data structure for handling `Clover.Message`s
  """

  alias Clover.{
    Message
  }

  import Kernel, except: [match?: 2]

  @type match_mode :: :overhear | :respond
  @type handler :: {module :: atom, function :: atom} | function()

  @enforce_keys [:match, :respond]

  defstruct match: nil,
            match_mode: :respond,
            respond: nil

  @type t :: %__MODULE__{
          match: Regex.t(),
          match_mode: match_mode,
          respond: handler
        }

  def handle(%__MODULE__{} = handler, %Message{} = message, data) do
    case match?(handler, message) do
      true -> respond(handler, message, data)
      false -> :nomatch
    end
  end

  def match?(%__MODULE__{match: match}, %Message{text: text}) do
    String.match?(text, match)
  end

  def respond(%__MODULE__{respond: {mod, fun}}, %Message{} = message, data) do
    match = %{}
    apply(mod, fun, [message, match, data])
  end

  def respond(%__MODULE__{respond: fun}, %Message{} = message, data) when is_function(fun) do
    match = %{}
    fun.(message, match, data)
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

  def new(mode, match, fun) when is_function(fun) do
    %__MODULE__{match: match, match_mode: mode, respond: fun}
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
end
