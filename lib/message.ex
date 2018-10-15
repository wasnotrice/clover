defmodule Clover.Message do
  @moduledoc """
  A Clover message
  """
  alias Clover.User

  @type mention :: {start :: non_neg_integer, length :: non_neg_integer}
  @type mentions :: %{required(String.t()) => mention}

  defstruct mentions: %{},
            robot: nil,
            room: nil,
            text: nil,
            type: nil,
            user: %User{}

  @type t :: %__MODULE__{
          mentions: mentions(),
          robot: String.t(),
          room: String.t(),
          text: String.t(),
          type: String.t(),
          user: User.t()
        }
end
