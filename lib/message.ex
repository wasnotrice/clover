defmodule Clover.Message do
  @moduledoc """
  A Clover message
  """
  alias Clover.User

  @type action :: :say | :typing
  @type mention :: {start :: non_neg_integer, length :: non_neg_integer}
  @type mentions :: %{required(String.t()) => mention}

  defstruct action: nil,
            delay: nil,
            robot: nil,
            room: nil,
            text: nil,
            type: nil,
            user: %User{}

  @type t :: %__MODULE__{
          action: action | nil,
          delay: non_neg_integer | nil,
          robot: String.t(),
          room: String.t() | nil,
          text: String.t(),
          type: String.t() | nil,
          user: User.t()
        }

  @doc """
  Scan the text of `message` for mentions, using `regex`.

  Returns a list of matches, with indexes. See `Regex.scan/3`

  ## Examples

      iex> mentions(%Message{text: "@alice hi"}, ~r/@(\\w+)/)
      [[{0, 6}, {1, 5}]]
  """
  def mentions(%__MODULE__{text: nil}, _), do: []

  def mentions(%__MODULE__{text: text}, regex) do
    Regex.scan(regex, text, return: :index)
  end

  @doc """
  Find a mention at the beginning of the message text, using `regex`.

  Returns a match, with indexes, or nil if no match. See `Regex.scan/3`

  ## Examples

  iex> leading_mention(%Message{text: "@alice hi"}, ~r/@(\\w+)/)
  [{0, 6}, {1, 5}]

  iex> leading_mention(%Message{text: "hi"}, ~r/@(\\w+)/)
  nil
  """

  def leading_mention(%__MODULE__{} = message, regex) do
    message
    |> mentions(regex)
    |> leading_mention()
  end

  def leading_mention(mentions) when is_list(mentions) do
    Enum.find(mentions, fn [match | _rest] ->
      elem(match, 0) == 0
    end)
  end

  @doc """
  Trim the text described by `mention` from `message`.

  Returns a `Clover.Message` with the trimmed text.

  ## Examples

  iex> trim_mention(%Message{text: "@alice hi"}, [{0, 6}, {1, 5}])
  %Clover.Message{
    robot: nil,
    room: nil,
    text: "hi",
    type: nil,
    user: %Clover.User{id: nil, name: nil}
  }

  iex> trim_mention(%Message{text: "@alice hi"}, [{7, 2}, {7, 2}])
  %Clover.Message{
    robot: nil,
    room: nil,
    text: "@alice",
    type: nil,
    user: %Clover.User{id: nil, name: nil}
  }

  iex> trim_mention(%Message{text: "oh @alice hi"}, [{3, 6}])
  %Clover.Message{
    robot: nil,
    room: nil,
    text: "oh  hi",
    type: nil,
    user: %Clover.User{id: nil, name: nil}
  }
  """
  def trim_mention(%__MODULE__{text: text} = message, [{start, length} | _captures]) do
    {prefix, postfix} = text |> String.split_at(start + length)
    prefix = prefix |> String.slice(0, start)
    Map.put(message, :text, String.trim(prefix <> postfix))
  end

  @doc """
  Trim the text matching `regex` from the beginning of the message text.

  Returns a `Clover.Message` with the trimmed text.

  ## Examples

  iex> trim_leading_mention(%Message{text: "@alice hi"}, ~r/@(\\w+)/)
  %Clover.Message{
    robot: nil,
    room: nil,
    text: "hi",
    type: nil,
    user: %Clover.User{id: nil, name: nil}
  }

  iex> trim_leading_mention(%Message{text: "hi @alice"}, ~r/@(\\w+)/)
  %Clover.Message{
    robot: nil,
    room: nil,
    text: "hi @alice",
    type: nil,
    user: %Clover.User{id: nil, name: nil}
  }
  """
  def trim_leading_mention(%__MODULE__{} = message, regex) do
    case leading_mention(message, regex) do
      nil -> message
      mention -> trim_mention(message, mention)
    end
  end

  def typing(%__MODULE__{} = message, options \\ []) do
    message
    |> Map.put(:action, :typing)
    |> Map.put(:text, nil)
    |> build_message(options)
  end

  def say(%__MODULE__{} = message, text, options \\ []) do
    message
    |> Map.put(:action, :say)
    |> Map.put(:text, text)
    |> build_message(options)
  end

  defp build_message(%__MODULE__{} = message, options) do
    Enum.reduce(options, message, &build_message/2)
  end

  defp build_message({:delay, delay}, message) do
    Map.put(message, :delay, delay)
  end
end
