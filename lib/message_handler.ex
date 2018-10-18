defmodule Clover.MessageHandler do
  @moduledoc """
  A data structure for handling `Clover.Message`s
  """

  alias Clover.{
    Message
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

  def handle(%__MODULE__{match: match, respond: respond}, %Message{text: text} = message, data) do
    case String.match?(text, match) do
      true -> respond.(message, data)
      false -> :nomatch
    end
  end
end
