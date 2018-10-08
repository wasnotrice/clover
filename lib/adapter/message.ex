defmodule Hugh.Adapter.Message do
  @callback from_external(message :: any, robot :: pid, context :: map) :: Hugh.Message.t()
  @callback to_external(Hugh.Message.t()) :: any
end
