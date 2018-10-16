defmodule Clover.MessageHandler do
  @moduledoc """
  A data structure for handling `Clover.Message`s
  """

  alias Clover.{
    User
  }

  import Kernel, except: [match?: 2]

  defstruct match: nil,
            mention?: true,
            options: [],
            respond: nil

  @type t :: %__MODULE__{
          match: Regex.t(),
          mention?: boolean,
          options: keyword,
          respond: function
        }

  def handle(%__MODULE__{match: match, respond: respond}, message, data) do
    trimmed_message = trim_leading_mention(message.text, Map.get(data, :me), message.mentions)

    case String.match?(trimmed_message, match) do
      true -> respond.(message, data)
      false -> :nomatch
    end
  end

  defp leading_mention(mentions, %User{id: id, name: name}) do
    Enum.find(mentions, fn {mention, {start, _}} ->
      start == 0 and (mention == id or mention == name)
    end)
  end

  defp trim_mention(text, {_, {_, length}}) do
    text |> String.split_at(length) |> elem(1) |> String.trim_leading()
  end

  defp trim_leading_mention(text, %User{} = user, mentions) do
    case leading_mention(mentions, user) do
      nil -> text
      mention -> trim_mention(text, mention)
    end
  end
end
