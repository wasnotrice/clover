defmodule Clover.Test.NoHandleInAdapter do
  @moduledoc false
  use Clover.Adapter

  @impl true
  def init(_, state), do: {:ok, state}

  @impl true
  def handle_out(_, _), do: :nothing
end

defmodule Clover.Test.NoHandleOutAdapter do
  @moduledoc false
  use Clover.Adapter

  @impl true
  def init(_, state), do: {:ok, state}

  @impl true
  def handle_in(_, _, _), do: :nothing
end

defmodule Clover.Test.NoInitAdapter do
  @moduledoc false
  use Clover.Adapter

  @impl true
  def handle_in(_, _, _), do: :nothing

  @impl true
  def handle_out(_, _), do: :nothing
end
