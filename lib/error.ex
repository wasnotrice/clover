defmodule Hugh.Error do
  defexception [:reason]

  def exception(reason),
    do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: reason}),
    do: Hugh.format_error(reason)
end
