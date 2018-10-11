defmodule Hugh.MessageHandler do
  defstruct match: nil,
            options: [],
            respond: nil

  @type t :: %__MODULE__{
          match: Regex.t(),
          options: keyword,
          respond: function
        }
end
