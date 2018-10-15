defmodule Clover.Adapter.Message do
  @callback from_external(message :: any, robot :: pid, context :: map) :: Clover.Message.t()
  @callback to_external(Clover.Message.t()) :: any
end
