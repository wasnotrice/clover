defmodule Clover.Error do
  defexception [:reason]

  def exception(reason),
    do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: reason}),
    do: Clover.format_error(reason)
end
