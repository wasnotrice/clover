defmodule Clover.Adapter.Message do
  @moduledoc """
  A behaviour for modules that transform messages to/from Clover messages
  """
  @callback from_external(message :: any, robot :: pid, context :: map) :: Clover.Message.t()
  @callback to_external(Clover.Message.t()) :: any
end
