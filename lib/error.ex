defmodule Clover.Error do
  @moduledoc """
  A Clover error
  """
  defexception [:reason]

  def exception(reason),
    do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: reason}),
    do: Clover.format_error(reason)
end
