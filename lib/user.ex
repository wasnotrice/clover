defmodule Hugh.User do
  @moduledoc """
  A chat user
  """

  defstruct id: nil,
            name: nil

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }
end
