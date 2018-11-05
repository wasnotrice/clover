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

# Note these adapters do not adopt the Clover.Adapter behaviour because they do not implement it correctly
# (which causes compiler warnings)

defmodule Clover.Test.NoNormalizeAdapter do
  @moduledoc false
  import Clover.Test.Factory

  def init(_, state), do: {:ok, state}
  def handle_out(_, state), do: {:sent, message(), state}
end

defmodule Clover.Test.NoHandleOutAdapter do
  @moduledoc false
  import Clover.Test.Factory

  def init(_, state), do: {:ok, state}
  def normalize(_, _), do: message()
end

defmodule Clover.Test.NoInitAdapter do
  @moduledoc false
  import Clover.Test.Factory

  def normalize(_, _), do: message()
  def handle_out(_, state), do: {:sent, message(), state}
end
