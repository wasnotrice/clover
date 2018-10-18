defmodule Clover.Test.Factory do
  @moduledoc false
  alias Clover.{Message, User}

  def message(opts \\ %{}) do
    %Message{
      text: "text",
      robot: "robot",
      user: %User{name: "ann", id: "ann"}
    }
    |> Map.merge(opts)
  end
end

defmodule Clover.Test.NoHandleInAdapter do
  @moduledoc false
  use Clover.Adapter
  import Clover.Test.Factory

  @impl true
  def init(_, state), do: {:ok, state}

  @impl true
  def handle_out(_, state), do: {:sent, message(), state}
end

defmodule Clover.Test.NoHandleOutAdapter do
  @moduledoc false
  use Clover.Adapter
  import Clover.Test.Factory

  @impl true
  def init(_, state), do: {:ok, state}

  @impl true
  def handle_in(_, _, state), do: {:message, message(), state}
end

defmodule Clover.Test.NoInitAdapter do
  @moduledoc false
  use Clover.Adapter
  import Clover.Test.Factory

  @impl true
  def handle_in(_, _, state), do: {:message, message(), state}

  @impl true
  def handle_out(_, state), do: {:sent, message(), state}
end
