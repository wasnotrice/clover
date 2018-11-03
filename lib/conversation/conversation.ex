defmodule Clover.Conversation do
  @moduledoc """
  A multi-message conversation

  A `Clover.Conversation` happens in a `Clover.Channel` between a robot and a `Clover.User`.
  """

  alias Clover.Message

  defstruct assigns: %{},
            transcript: []

  @type t :: %__MODULE__{
          assigns: map,
          transcript: [Message.t()]
        }

  def new() do
    %__MODULE__{}
  end
end
