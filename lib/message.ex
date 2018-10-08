defmodule Hugh.Message do
  @moduledoc """
  A Hugh message
  """
  alias Hugh.User

  defstruct robot: nil,
            room: nil,
            text: nil,
            type: nil,
            user: %User{}

  @type t :: %__MODULE__{
          robot: pid(),
          room: String.t(),
          text: String.t(),
          type: String.t(),
          user: User.t()
        }
end
